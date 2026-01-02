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
    /// 외부 딥링크와 initialStep을 위해 버퍼링 지원
    private let stepsSubject = AsyncReplaySubject<Step>(bufferSize: 1)

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
        currentFlow = flow
        self.allowStepWhenDismissed = allowStepWhenDismissed

        startListeningToSteps(for: flow)

        Task { @MainActor in
            let initialStep = stepper.initialStep
            if !(initialStep is NoneStep) {
                self.stepsSubject.send(initialStep)
            }
        }

        stepper.readyToEmitSteps()
        startListeningToStepperEvents(stepper, for: flow)
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

    private func startListeningToSteps(for flow: Flow) {
        let taskId = UUID()
        let task = Task { @MainActor [weak self, weak flow] in
            guard let flow = flow, let self = self else { return }

            for await step in self.stepsSubject.stream {
                guard !Task.isCancelled else { break }
                await self.handleStep(step, in: flow)
            }

            self.removeTask(taskId)
        }

        activeTasks[taskId] = task

        if !allowStepWhenDismissed {
            registerDismissHandler(for: flow, taskId: taskId)
        }
    }

    private func startListeningToStepperEvents(_ stepper: FlowStepper, for flow: Flow) {
        let taskId = UUID()
        let task = createStepperListenerTask(stepper: stepper)
        activeTasks[taskId] = task

        if !allowStepWhenDismissed {
            registerFlowDismissHandler(for: flow, cancelingTask: taskId)
        }
    }

    private func createStepperListenerTask(stepper: FlowStepper) -> Task<Void, Never> {
        Task { [weak self, weak stepper] in
            guard let stepper = stepper else { return }

            for await step in stepper.steps.stream {
                guard !Task.isCancelled, !(step is NoneStep) else { continue }
                self?.stepsSubject.send(step)
            }
        }
    }

    private func registerFlowDismissHandler(for flow: Flow, cancelingTask taskId: UUID) {
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

    private func handleStep(_ step: Step, in flow: Flow) async {
        let adaptedStep = await flow.adapt(step: step)
        guard !(adaptedStep is NoneStep) else { return }

        let event = NavigationEvent(flow: flow, step: adaptedStep)
        willNavigateBridge.send(event)

        let contributors = flow.navigate(to: adaptedStep)

        didNavigateBridge.send(event)

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

    private func startListeningToPresentableStepperEvents(
        presentable: Presentable,
        stepper: FlowStepper,
        in _: Flow,
        allowStepWhenNotPresented: Bool,
        allowStepWhenDismissed: Bool
    ) {
        let taskId = UUID()
        let visibilityState = VisibilityState()

        if !allowStepWhenNotPresented {
            registerVisibilityHandler(for: presentable, state: visibilityState)
        }

        let task = Task { [weak self, weak stepper] in
            guard let stepper = stepper else { return }

            for await step in stepper.steps.stream {
                guard !Task.isCancelled, !(step is NoneStep) else { continue }

                if allowStepWhenNotPresented {
                    self?.stepsSubject.send(step)
                } else {
                    await self?.handleStepWithVisibility(step, state: visibilityState)
                }
            }

            self?.removeTask(taskId)
        }

        activeTasks[taskId] = task

        if !allowStepWhenDismissed {
            registerPresentableDismissHandler(for: presentable, taskId: taskId)
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

    private func registerDismissHandler(for flow: Flow, taskId _: UUID) {
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

    private func registerPresentableDismissHandler(for presentable: Presentable, taskId: UUID) {
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

    private func registerVisibilityHandler(for presentable: Presentable, state: VisibilityState) {
        let visibilityTaskId = UUID()
        let visibilityTask = Task { [weak self] in
            for await isVisible in presentable.isVisibleStream {
                state.isVisible = isVisible
                state.isInitialized = true

                if isVisible {
                    for bufferedStep in state.bufferedSteps {
                        self?.stepsSubject.send(bufferedStep)
                    }
                    state.bufferedSteps.removeAll()
                }
            }

            self?.removeTask(visibilityTaskId)
        }
        activeTasks[visibilityTaskId] = visibilityTask
    }

    private func handleStepWithVisibility(_ step: Step, state: VisibilityState) async {
        if !state.isInitialized {
            await waitForVisibilityInitialization(state: state)
        }

        if state.isVisible {
            stepsSubject.send(step)
        } else {
            state.bufferedSteps.append(step)
        }
    }

    private func waitForVisibilityInitialization(state: VisibilityState) async {
        let deadline = Date().addingTimeInterval(1.0)
        while !state.isInitialized, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        if !state.isInitialized {
            state.isVisible = true
            state.isInitialized = true
        }
    }

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

// MARK: - VisibilityState

/// Presentable의 가시성 상태를 추적하는 클래스
@MainActor
private final class VisibilityState {
    var isVisible: Bool = true // 기본값은 true (초기에 보이는 상태로 가정)
    var isInitialized: Bool = false // 가시성 스트림에서 첫 값을 받았는지 여부
    var bufferedSteps: [Step] = []
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
