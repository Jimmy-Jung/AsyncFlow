import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class ScreenViewModel: ObservableObject, FlowStepper {
    // MARK: - Types

    enum Input: Equatable, Sendable {
        case nextButtonTapped
        case backButtonTapped(Int)
        case goToRootButtonTapped
        case jumpToScreenButtonTapped(DemoStep.Screen)
        case deepLinkButtonTapped(DemoStep.Screen)
        case viewDidAppear
        case viewDidDisappear
    }

    enum Action: Equatable, Sendable {
        case navigateToNext
        case navigateBack(Int)
        case navigateToRoot
        case navigateToScreen(DemoStep.Screen)
        case navigateDeepLink(DemoStep.Screen)
        case updateStackInfo(String)
    }

    struct State: Equatable, Sendable {
        var config: ScreenConfig
        var stackInfo: String = ""
        var canGoBack: Bool = false
        var canGoBack2: Bool = false
        var canGoBack3: Bool = false
        var canGoToRoot: Bool = false
        var nextScreen: DemoStep.Screen?
    }

    enum CancelID: Hashable, Sendable {
        case updateStack
    }

    // MARK: - Properties

    @Published var state: State
    @Steps var steps: AsyncPassthroughSubject<Step>

    var initialStep: Step {
        NoneStep()
    }

    // MARK: - Initialization

    init(screen: DemoStep.Screen, depth: Int) {
        let config = ScreenConfig.all[screen]!

        // 다음 화면 계산
        let nextScreen: DemoStep.Screen? = {
            let allScreens = DemoStep.Screen.allCases
            guard let currentIndex = allScreens.firstIndex(of: screen),
                  currentIndex < allScreens.count - 1 else { return nil }
            return allScreens[currentIndex + 1]
        }()

        state = State(
            config: config,
            stackInfo: "Stack Depth: \(depth)",
            canGoBack: depth >= 1,
            canGoBack2: depth >= 2,
            canGoBack3: depth >= 3,
            canGoToRoot: depth >= 1,
            nextScreen: nextScreen
        )
    }

    // MARK: - FlowStepper

    func readyToEmitSteps() {
        // FlowCoordinator가 Stepper를 구독할 때 호출됨
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .nextButtonTapped:
            return [.navigateToNext]
        case let .backButtonTapped(count):
            return [.navigateBack(count)]
        case .goToRootButtonTapped:
            return [.navigateToRoot]
        case let .jumpToScreenButtonTapped(screen):
            return [.navigateToScreen(screen)]
        case let .deepLinkButtonTapped(screen):
            return [.navigateDeepLink(screen)]
        case .viewDidAppear:
            return [.updateStackInfo("Loading stack info...")]
        case .viewDidDisappear:
            return []
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .navigateToNext:
            if let next = state.nextScreen {
                steps.send(next.toStep())
            }
            return [.none]

        case let .navigateBack(count):
            if count == 1 {
                steps.send(DemoStep.goBack)
            } else if count == 2 {
                steps.send(DemoStep.goBack2)
            } else if count == 3 {
                steps.send(DemoStep.goBack3)
            }
            return [.none]

        case .navigateToRoot:
            steps.send(DemoStep.goToRoot)
            return [.none]

        case let .navigateToScreen(screen):
            steps.send(DemoStep.goToSpecific(screen))
            return [.none]

        case let .navigateDeepLink(screen):
            steps.send(DemoStep.deepLink(screen))
            return [.none]

        case let .updateStackInfo(info):
            state.stackInfo = info
            return [.none]
        }
    }

    // MARK: - Error Handling

    func handleError(_ error: SendableError) {
        print("Error in ScreenViewModel: \(error.localizedDescription)")
    }
}

extension DemoStep.Screen {
    func toStep() -> DemoStep {
        switch self {
        case .screenA: return .screenA
        case .screenB: return .screenB
        case .screenC: return .screenC
        case .screenD: return .screenD
        case .screenE: return .screenE
        }
    }
}
