//
//  FlowCoordinator.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation
import UIKit

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

    /// 네비게이션 스택 추적 (Flow별)
    private var navigationStacks: [String: [StepInfo]] = [:]

    /// NavigationFlow별 마지막 로깅된 스택 상태 (중복 로깅 방지용)
    /// 키가 없으면 아직 로깅된 적이 없음을 의미
    private var lastLoggedStacks: [String: [StepInfo]] = [:]

    /// Flow별 마지막 Step (NavigationFlow 스택 업데이트용)
    private var lastSteps: [String: Step] = [:]

    /// 로거
    private let logger: FlowLogger

    public init(logger: FlowLogger? = nil) {
        self.logger = logger ?? NoOpFlowLogger()
        UIViewController.enableAsyncFlowSwizzling()
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

        // NavigationFlow인 경우 onStackChanged 콜백 연결
        // navigationController(_:didShow:animated:)에서 호출되며,
        // 실제 viewControllers를 기반으로 스택을 재구성하고 로깅합니다.
        if let navigationFlow = flow as? NavigationFlow {
            let flowName = String(describing: type(of: flow))
            navigationFlow.onStackChanged = { [weak self, weak navigationFlow] in
                guard let self = self, let navigationFlow = navigationFlow else { return }
                Task { @MainActor in
                    // 마지막 Step을 사용하여 스택 업데이트 (실제로는 viewControllers 기반)
                    let lastStep = self.lastSteps[flowName] ?? NoneStep()
                    self.updateNavigationStack(for: navigationFlow, with: lastStep)
                }
            }
        }

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

        // 마지막 Step 저장 (NavigationFlow의 onStackChanged 콜백에서 사용)
        let flowName = String(describing: type(of: flow))
        lastSteps[flowName] = adaptedStep

        // 스택 업데이트 및 로깅
        // NavigationFlow의 경우 여기서 즉시 로깅하고,
        // navigationController(_:didShow:animated:)에서 onStackChanged 콜백이 호출될 때
        // 중복 방지 로직이 동일한 스택에 대한 재로깅을 막아줍니다.
        updateNavigationStack(for: flow, with: adaptedStep)
    }

    /// 네비게이션 스택 업데이트 및 로깅
    private func updateNavigationStack(for flow: Flow, with step: Step) {
        let flowName = String(describing: type(of: flow))

        // 마지막 Step 저장 (NavigationFlow의 didShow에서 사용)
        if !(step is NoneStep) {
            lastSteps[flowName] = step
        }

        // NavigationFlow인 경우 실제 viewControllers를 기반으로 스택 재구성
        let currentSteps: [StepInfo]

        if let navigationFlow = flow as? NavigationFlow {
            // 실제 viewControllers를 기반으로 스택 재구성 (metadata 포함)
            currentSteps = navigationFlow.navigationController.viewControllers.compactMap { viewController in
                guard let step = navigationFlow.associatedStep(for: viewController) else { return nil }
                // Stepper에서 metadata 추출
                let metadata = navigationFlow.associatedStepper(for: viewController)?.metadata
                return StepInfo(step: step, metadata: metadata)
            }
        } else {
            // 일반 Flow: step이 NoneStep이 아닌 경우에만 append
            if !(step is NoneStep) {
                let stepInfo = StepInfo(step: step)
                if navigationStacks[flowName] == nil {
                    navigationStacks[flowName] = []
                }
                navigationStacks[flowName]?.append(stepInfo)
            }
            currentSteps = navigationStacks[flowName] ?? []
        }

        // 로그 출력 (NavigationFlow의 경우 스택이 비어있어도 출력, 일반 Flow는 비어있지 않은 경우에만)
        if flow is NavigationFlow {
            // NavigationFlow는 스택 상태가 변경된 경우에만 로그 출력 (중복 로깅 방지)
            // lastLoggedStacks에 키가 없으면 아직 로깅된 적이 없으므로 항상 로깅
            if let lastLogged = lastLoggedStacks[flowName] {
                // StepInfo 배열 비교 (Equatable이 아니므로 수동 비교)
                // typeName, caseDescription, displayName 모두 비교
                let isStackChanged = currentSteps.count != lastLogged.count ||
                    zip(currentSteps, lastLogged).contains { step1, step2 in
                        step1.typeName != step2.typeName ||
                            step1.caseDescription != step2.caseDescription ||
                            step1.displayName != step2.displayName
                    }

                // 스택이 변경되지 않았으면 로깅하지 않음
                guard isStackChanged else { return }
            }

            // 스택이 변경되었거나 첫 로깅인 경우 로깅
            let navigationStack = NavigationStack(
                flowName: flowName,
                steps: currentSteps
            )
            logger.log(navigationStack: navigationStack)
            lastLoggedStacks[flowName] = currentSteps
        } else if !currentSteps.isEmpty {
            // 일반 Flow는 스택이 있을 때만 출력
            let navigationStack = NavigationStack(
                flowName: flowName,
                steps: currentSteps
            )
            logger.log(navigationStack: navigationStack)
        }
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

        // NavigationFlow의 경우 onStackChanged 콜백은 coordinate()에서 이미 설정되었으므로
        // 여기서는 다시 설정하지 않습니다. (중복 로깅 방지)
    }

    /// 개별 FlowContributor 처리
    private func handleFlowContributor(_ contributor: FlowContributor, in flow: Flow) async {
        switch contributor {
        case let .contribute(presentable, stepper, allowStepWhenNotPresented, allowStepWhenDismissed):
            // 자식 Flow인 경우
            if let childFlow = presentable as? Flow {
                let childCoordinator = FlowCoordinator(logger: logger) // 부모의 logger 전달
                childCoordinator.parentFlowCoordinator = self
                childFlowCoordinators[childCoordinator.identifier] = childCoordinator

                // coordinate()에서 콜백이 설정되므로 여기서는 제거
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

        // 네비게이션 스택 정리
        navigationStacks.removeAll()
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
