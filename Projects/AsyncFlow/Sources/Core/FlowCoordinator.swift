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

    public var willNavigate: AsyncStream<NavigationEvent> {
        willNavigateBridge.stream
    }

    public var didNavigate: AsyncStream<NavigationEvent> {
        didNavigateBridge.stream
    }

    private let willNavigateBridge = AsyncStreamBridge<NavigationEvent>()
    private let didNavigateBridge = AsyncStreamBridge<NavigationEvent>()

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
        #if canImport(UIKit)
            UIViewController.enableAsyncFlowSwizzling()
        #endif

        #if canImport(AppKit)
            NSViewController.enableAsyncFlowSwizzling()
        #endif
    }

    // MARK: - Public Methods

    public func coordinate<F: Flow, S: Stepper>(
        flow: F,
        with stepper: S
    ) where F.StepType == S.StepType {
        startListening(to: stepper, in: flow, presentable: flow)
    }

    // MARK: - Private Methods

    private func startListening<F: Flow, S: Stepper>(
        to stepper: S,
        in flow: F,
        presentable: Presentable? = nil
    ) where F.StepType == S.StepType {
        let taskId = UUID()
        let stepperTask = createStepperTask(for: stepper, in: flow, taskId: taskId)
        let lifecycleTask = createLifecycleTask(for: presentable, stepperTask: stepperTask)

        tasks[taskId] = ContributorTasks(
            stepperTask: stepperTask,
            lifecycleTask: lifecycleTask
        )
    }

    private func createStepperTask<F: Flow, S: Stepper>(
        for stepper: S,
        in flow: F,
        taskId: UUID
    ) -> Task<Void, Never> where F.StepType == S.StepType {
        Task { [weak self] in
            defer { self?.removeTask(taskId) }
            for await step in stepper.steps {
                await self?.handleStep(step, in: flow)
            }
        }
    }

    private func createLifecycleTask(
        for presentable: Presentable?,
        stepperTask: Task<Void, Never>
    ) -> Task<Void, Never>? {
        guard let presentable = presentable else { return nil }

        return Task {
            for await _ in presentable.onDismissed {
                stepperTask.cancel()
                break
            }
        }
    }

    private func removeTask(_ id: UUID) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }

    private func handleStep<F: Flow>(
        _ step: F.StepType,
        in flow: F
    ) async {
        guard let adaptedStep = await flow.adapt(step: step) else { return }

        let event = NavigationEvent(flow: flow, step: adaptedStep)
        willNavigateBridge.yield(event)

        let contributors = await flow.navigate(to: adaptedStep)
        didNavigateBridge.yield(event)

        await registerContributors(contributors, in: flow)
    }

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

    private func registerContributor<F: Flow>(
        _ contributor: FlowContributor<F.StepType>,
        in flow: F
    ) async {
        guard case let .contribute(presentable, stepper) = contributor else { return }

        if let childFlow = presentable as? F {
            coordinate(flow: childFlow, with: stepper)
        } else {
            startListening(to: stepper, in: flow, presentable: presentable)
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
