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
/// FlowCoordinator는 Flow와 Stepper를 관리하고 Step을 처리합니다.
/// RxFlow와 동일하게 부모-자식 FlowCoordinator 관계를 지원합니다.
///
/// ## 사용 예시
///
/// ```swift
/// class AppDelegate: UIResponder, UIApplicationDelegate {
///     let coordinator = FlowCoordinator()
///
///     func application(_ application: UIApplication,
///                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
///
///         let appFlow = AppFlow(window: window)
///         let appStepper = OneStepper(withSingleStep: AppStep.launch)
///
///         // 네비게이션 이벤트 구독
///         Task {
///             for await event in coordinator.didNavigate {
///                 print("did navigate: \(event)")
///             }
///         }
///
///         coordinator.coordinate(flow: appFlow, with: appStepper)
///
///         return true
///     }
/// }
/// ```
@MainActor
public final class FlowCoordinator {
    // MARK: - Properties

    /// 네비게이션 시작 전 이벤트 스트림
    public var willNavigate: AsyncStream<NavigationEvent> {
        willNavigateBridge.stream
    }

    /// 네비게이션 완료 후 이벤트 스트림
    public var didNavigate: AsyncStream<NavigationEvent> {
        didNavigateBridge.stream
    }

    private let willNavigateBridge = AsyncPassthroughSubject<NavigationEvent>()
    private let didNavigateBridge = AsyncPassthroughSubject<NavigationEvent>()

    /// Step을 집계하는 Subject
    private let stepsSubject = AsyncPassthroughSubject<Step>()

    /// 고유 식별자
    let identifier = UUID().uuidString

    /// 자식 FlowCoordinator 딕셔너리
    private var childFlowCoordinators: [String: FlowCoordinator] = [:]

    /// 부모 FlowCoordinator (weak reference)
    private weak var parentFlowCoordinator: FlowCoordinator? {
        didSet {
            if let parent = parentFlowCoordinator {
                // 부모에게 네비게이션 이벤트 전파
                forwardNavigationEvents(to: parent)
            }
        }
    }

    /// 현재 조율 중인 Flow
    private weak var currentFlow: Flow?

    /// 현재 활성화된 Task들
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    /// allowStepWhenDismissed 플래그
    private var allowStepWhenDismissed: Bool = false

    public init() {
        #if canImport(UIKit)
            UIViewController.enableAsyncFlowSwizzling()
        #endif

        #if canImport(AppKit)
            NSViewController.enableAsyncFlowSwizzling()
        #endif
    }

    // MARK: - Public Methods

    /// Flow와 Stepper로 네비게이션 시작
    ///
    /// - Parameters:
    ///   - flow: 조율할 Flow
    ///   - stepper: Flow를 구동할 Stepper
    ///   - allowStepWhenDismissed: dismiss되어도 Step 허용 여부 (기본값: false)
    public func coordinate(
        flow: Flow,
        with stepper: FlowStepper,
        allowStepWhenDismissed: Bool = false
    ) {
        print("🎯 FlowCoordinator.coordinate called for flow: \(type(of: flow))")
        currentFlow = flow
        self.allowStepWhenDismissed = allowStepWhenDismissed

        // Step Subject 구독 시작
        startListeningToSteps(for: flow)

        // Task가 시작될 때까지 잠시 대기 (버퍼링이 제대로 작동하도록)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01초 대기

            // initialStep을 stepsSubject에 전송
            // AsyncPassthroughSubject가 버퍼링을 지원하므로 안전함
            let initialStep = stepper.initialStep
            print("📤 Sending initialStep: \(initialStep)")
            if !(initialStep is NoneStep) {
                self.stepsSubject.send(initialStep)
                print("✅ initialStep sent to stepsSubject")
            } else {
                print("⚠️ initialStep is NoneStep, skipping")
            }
        }

        // readyToEmitSteps 호출
        stepper.readyToEmitSteps()

        // 이후 Step 이벤트 구독
        startListeningToStepperEvents(stepper, for: flow)
        print("✅ FlowCoordinator.coordinate completed")
    }

    /// 외부에서 Step을 직접 주입
    ///
    /// DeepLink 처리 등에 사용됩니다.
    /// 주입된 Step은 모든 자식 Flow에도 전파됩니다.
    ///
    /// - Parameter step: 주입할 Step
    public func navigate(to step: Step) {
        stepsSubject.send(step)
        childFlowCoordinators.values.forEach { $0.navigate(to: step) }
    }

    // MARK: - Private Methods

    /// Step Subject 구독
    private func startListeningToSteps(for flow: Flow) {
        print("👂 startListeningToSteps called")
        let taskId = UUID()
        let task = Task { @MainActor [weak self, weak flow] in
            guard let flow = flow else {
                print("⚠️ flow is nil in startListeningToSteps")
                return
            }
            guard let self = self else {
                print("⚠️ self is nil in startListeningToSteps")
                return
            }

            print("👂 Starting to listen to stepsSubject.stream")
            for await step in self.stepsSubject.stream {
                guard !Task.isCancelled else {
                    print("⚠️ Task cancelled")
                    break
                }
                print("📥 Received step from stream: \(step)")
                await self.handleStep(step, in: flow)
            }

            self.removeTask(taskId)
        }

        activeTasks[taskId] = task
        print("✅ Task registered for listening to steps")

        // Flow dismiss 시 정리
        if !allowStepWhenDismissed {
            let dismissTaskId = UUID()
            let dismissTask = Task { [weak self, weak flow] in
                guard let flow = flow else { return }

                for await _ in flow.onDismissed {
                    self?.cleanup()
                    break
                }

                self?.removeTask(dismissTaskId)
            }
            activeTasks[dismissTaskId] = dismissTask
        }
    }

    /// FlowStepper 이벤트 구독 (initialStep 제외)
    private func startListeningToStepperEvents(_ stepper: FlowStepper, for flow: Flow) {
        let taskId = UUID()
        let task = Task { [weak self, weak stepper] in
            guard let stepper = stepper else { return }

            // Stepper의 steps 스트림 구독
            for await step in stepper.steps.stream {
                guard !Task.isCancelled else { break }

                if step is NoneStep { continue }
                self?.stepsSubject.send(step)
            }

            self?.removeTask(taskId)
        }

        activeTasks[taskId] = task

        // Flow dismiss 시 구독 해제
        if !allowStepWhenDismissed {
            let dismissTaskId = UUID()
            let dismissTask = Task { [weak self, weak flow] in
                guard let flow = flow else { return }

                for await _ in flow.onDismissed {
                    self?.activeTasks[taskId]?.cancel()
                    break
                }

                self?.removeTask(dismissTaskId)
            }
            activeTasks[dismissTaskId] = dismissTask
        }
    }

    /// Step 처리
    private func handleStep(_ step: Step, in flow: Flow) async {
        print("🔄 handleStep called with step: \(step)")
        // Step 적응 (필터링)
        let adaptedStep = await flow.adapt(step: step)
        print("🔄 adaptedStep: \(adaptedStep)")
        if adaptedStep is NoneStep {
            print("⚠️ adaptedStep is NoneStep, returning")
            return
        }

        // willNavigate 이벤트 발생
        let event = NavigationEvent(flow: flow, step: adaptedStep)
        willNavigateBridge.send(event)

        // 네비게이션 수행
        print("🚀 Calling flow.navigate(to: \(adaptedStep))")
        let contributors = flow.navigate(to: adaptedStep)
        print("✅ flow.navigate returned: \(contributors)")

        // didNavigate 이벤트 발생
        didNavigateBridge.send(event)

        // FlowContributors 처리
        await handleFlowContributors(contributors, in: flow)
    }

    /// FlowContributors 처리
    private func handleFlowContributors(_ contributors: FlowContributors, in flow: Flow) async {
        switch contributors {
        case .none:
            break

        case let .one(flowContributor):
            await handleFlowContributor(flowContributor, in: flow)

        case let .multiple(flowContributors):
            for contributor in flowContributors {
                await handleFlowContributor(contributor, in: flow)
            }

        case let .end(forwardToParentFlowWithStep):
            // 부모 Flow에 Step 전달
            parentFlowCoordinator?.stepsSubject.send(forwardToParentFlowWithStep)
            // 현재 FlowCoordinator 정리
            cleanup()
            // 부모에서 제거
            parentFlowCoordinator?.childFlowCoordinators.removeValue(forKey: identifier)
        }
    }

    /// 개별 FlowContributor 처리
    private func handleFlowContributor(_ contributor: FlowContributor, in flow: Flow) async {
        switch contributor {
        case let .contribute(presentable, stepper, allowStepWhenNotPresented, allowStepWhenDismissed):
            // 자식 Flow인 경우
            if let childFlow = presentable as? Flow {
                let childCoordinator = FlowCoordinator()
                childCoordinator.parentFlowCoordinator = self
                childFlowCoordinators[childCoordinator.identifier] = childCoordinator
                childCoordinator.coordinate(
                    flow: childFlow,
                    with: stepper,
                    allowStepWhenDismissed: allowStepWhenDismissed
                )

                // Flow readiness 설정
                setReadiness(for: flow, basedOn: [presentable])
            } else {
                // 일반 Presentable인 경우
                // initialStep 즉시 처리
                let initialStep = stepper.initialStep
                if !(initialStep is NoneStep) {
                    await handleStep(initialStep, in: flow)
                }

                // readyToEmitSteps 호출
                stepper.readyToEmitSteps()

                // 이후 Step 이벤트 구독
                startListeningToPresentableStepperEvents(
                    presentable: presentable,
                    stepper: stepper,
                    in: flow,
                    allowStepWhenNotPresented: allowStepWhenNotPresented,
                    allowStepWhenDismissed: allowStepWhenDismissed
                )
            }

        case let .forwardToCurrentFlow(step):
            // 비동기로 현재 Flow에 Step 전달
            Task { @MainActor [weak self] in
                self?.stepsSubject.send(step)
            }

        case let .forwardToParentFlow(step):
            // 부모 Flow에 Step 전달
            parentFlowCoordinator?.stepsSubject.send(step)
        }
    }

    /// Presentable/FlowStepper 이벤트 구독 (initialStep 제외)
    private func startListeningToPresentableStepperEvents(
        presentable: Presentable,
        stepper: FlowStepper,
        in _: Flow,
        allowStepWhenNotPresented: Bool,
        allowStepWhenDismissed: Bool
    ) {
        let taskId = UUID()
        let task = Task { [weak self, weak stepper] in
            guard let stepper = stepper else { return }

            // Stepper의 steps 스트림 구독
            for await step in stepper.steps.stream {
                guard !Task.isCancelled else { break }

                if step is NoneStep { continue }

                // allowStepWhenNotPresented 체크
                if !allowStepWhenNotPresented {
                    // isVisibleStream의 현재 상태 확인은 복잡하므로 일단 항상 허용
                    // FIXME: 필요시 pausable 로직 구현
                }

                self?.stepsSubject.send(step)
            }

            self?.removeTask(taskId)
        }

        activeTasks[taskId] = task

        // Presentable dismiss 시 구독 해제
        if !allowStepWhenDismissed {
            let dismissTaskId = UUID()
            let dismissTask = Task { [weak self] in
                for await _ in presentable.onDismissed {
                    self?.activeTasks[taskId]?.cancel()
                    break
                }

                self?.removeTask(dismissTaskId)
            }
            activeTasks[dismissTaskId] = dismissTask
        }
    }

    /// Flow readiness 설정
    private func setReadiness(for flow: Flow, basedOn presentables: [Presentable]) {
        let childFlows = presentables.compactMap { $0 as? Flow }

        if childFlows.isEmpty {
            flow.flowReadySubject.send(true)
        } else {
            Task { @MainActor [weak flow] in
                // 모든 자식 Flow가 ready될 때까지 대기
                for childFlow in childFlows where !Task.isCancelled {
                    for await ready in childFlow.flowReady where ready {
                        break
                    }
                }
                flow?.flowReadySubject.send(true)
            }
        }
    }

    /// 네비게이션 이벤트를 부모에게 전파
    private func forwardNavigationEvents(to parent: FlowCoordinator) {
        Task { @MainActor [weak self, weak parent] in
            guard let stream = self?.willNavigateBridge.stream else { return }
            for await event in stream {
                parent?.willNavigateBridge.send(event)
            }
        }

        Task { @MainActor [weak self, weak parent] in
            guard let stream = self?.didNavigateBridge.stream else { return }
            for await event in stream {
                parent?.didNavigateBridge.send(event)
            }
        }
    }

    /// Task 제거
    private func removeTask(_ id: UUID) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
    }

    /// 정리
    private func cleanup() {
        // 모든 활성 Task 취소
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()

        // 모든 자식 FlowCoordinator 정리
        for child in childFlowCoordinators.values {
            child.cleanup()
        }
        childFlowCoordinators.removeAll()
    }
}

// MARK: - NavigationEvent

/// 네비게이션 이벤트
public struct NavigationEvent: Sendable {
    public let flowType: String
    public let stepDescription: String

    init(flow: Flow, step: Step) {
        flowType = String(describing: type(of: flow))
        stepDescription = String(describing: step)
    }
}
