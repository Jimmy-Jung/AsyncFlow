//
//  FlowCoordinator.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

/// 전체 네비게이션을 조율하는 코디네이터
///
/// FlowCoordinator는 앱에 단 하나만 존재하며,
/// 모든 Flow와 Stepper를 관리하고 Step을 처리합니다.
@MainActor
public final class FlowCoordinator {
    // MARK: - Properties

    /// 네비게이션 직전 이벤트 스트림
    public var willNavigate: AsyncStream<NavigationEvent> {
        willNavigateBridge.stream
    }

    /// 네비게이션 완료 이벤트 스트림
    public var didNavigate: AsyncStream<NavigationEvent> {
        didNavigateBridge.stream
    }

    private let willNavigateBridge = AsyncStreamBridge<NavigationEvent>()
    private let didNavigateBridge = AsyncStreamBridge<NavigationEvent>()

    /// Flow별 관리되는 Task들
    private struct ContributorTasks {
        let stepperTask: Task<Void, Never>
        let lifecycleTask: Task<Void, Never>?

        func cancel() {
            stepperTask.cancel()
            lifecycleTask?.cancel()
        }
    }

    private var tasks: [UUID: ContributorTasks] = [:]

    public init() {
        // UIKit 환경이라면 자동으로 Swizzling 활성화 시도
        #if canImport(UIKit)
            UIViewController.enableAsyncFlowSwizzling()
        #endif

        // AppKit 환경이라면 자동으로 Swizzling 활성화 시도
        #if canImport(AppKit)
            NSViewController.enableAsyncFlowSwizzling()
        #endif
    }

    // MARK: - Public Methods

    /// Flow 조율 시작
    public func coordinate<F: Flow, S: Stepper>(
        flow: F,
        with stepper: S
    ) where F.StepType == S.StepType {
        // Flow 자체가 Presentable이므로 이를 감시 대상으로 설정
        startListening(to: stepper, in: flow, presentable: flow)
    }

    // MARK: - Private Methods

    /// Stepper의 Step 스트림을 감시
    private func startListening<F: Flow, S: Stepper>(
        to stepper: S,
        in flow: F,
        presentable: Presentable? = nil
    ) where F.StepType == S.StepType {
        let taskId = UUID()

        // 1. Stepper 감시 Task
        let stepperTask = Task { [weak self] in
            // Task 종료 시 자동 정리 (Self-Cleaning)
            defer { self?.removeTask(taskId) }

            for await step in stepper.steps {
                await self?.handleStep(step, in: flow)
            }
        }

        // 2. Lifecycle 감시 Task (화면 닫힘 감지)
        // Task는 구조체이므로 weak capture가 불가능하며, 불필요합니다.
        // 그냥 캡처해도 순환 참조가 발생하지 않습니다.
        var lifecycleTask: Task<Void, Never>?

        if let presentable = presentable, presentable.allowStepWhenDismissed == false {
            lifecycleTask = Task {
                // Presentable이 닫힐 때까지 대기
                for await _ in presentable.onDismissed {
                    // 화면이 닫히면 Stepper도 중단
                    stepperTask.cancel()
                    break
                }
            }
        } else if let presentable = presentable {
            // allowStepWhenDismissed가 true라도(기본값), onDismissed가 발생하면
            // 메모리 정리를 위해 감시할 필요가 있는지 확인해야 함.
            lifecycleTask = Task {
                for await _ in presentable.onDismissed {
                    stepperTask.cancel()
                    break
                }
            }
        }

        tasks[taskId] = ContributorTasks(
            stepperTask: stepperTask,
            lifecycleTask: lifecycleTask
        )
    }

    private func removeTask(_ id: UUID) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }

    /// Step 처리
    private func handleStep<F: Flow>(
        _ step: F.StepType,
        in flow: F
    ) async {
        // 1. Step 적응 (필터링/변환)
        guard let adaptedStep = await flow.adapt(step: step) else {
            return
        }

        // 2. willNavigate 발행
        let event = NavigationEvent(flow: flow, step: adaptedStep)
        willNavigateBridge.yield(event)

        // 3. 네비게이션 실행
        let contributors = await flow.navigate(to: adaptedStep)

        // 4. didNavigate 발행
        didNavigateBridge.yield(event)

        // 5. 새 Contributor 등록
        await registerContributors(contributors, in: flow)
    }

    /// FlowContributors 등록
    private func registerContributors<F: Flow>(
        _ contributors: FlowContributors<F.StepType>,
        in flow: F
    ) async {
        switch contributors {
        case .none:
            break

        case let .one(contributor):
            await registerContributor(contributor, in: flow)

        case let .multiple(contributorList):
            for contributor in contributorList {
                await registerContributor(contributor, in: flow)
            }
        }
    }

    /// 단일 FlowContributor 등록
    private func registerContributor<F: Flow>(
        _ contributor: FlowContributor<F.StepType>,
        in flow: F
    ) async {
        switch contributor {
        case let .contribute(presentable, stepper):
            // Presentable이 Flow인 경우
            if let childFlow = presentable as? F {
                // Child Flow 시작
                coordinate(flow: childFlow, with: stepper)
            } else {
                // ViewController인 경우
                startListening(to: stepper, in: flow, presentable: presentable)
            }

        case .none:
            break
        }
    }
}

// MARK: - Supporting Types

/// 네비게이션 이벤트
public struct NavigationEvent: Sendable {
    public let flowType: String
    public let stepDescription: String

    init<F: Flow>(flow: F, step: F.StepType) {
        flowType = String(describing: type(of: flow))
        stepDescription = String(describing: step)
    }
}
