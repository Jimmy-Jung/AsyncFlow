# AsyncFlow

Swift Concurrency 기반 iOS 네비게이션 프레임워크

## 개요

AsyncFlow는 RxFlow의 Reactive Flow Coordinator 패턴을 Swift Concurrency로 재설계한 네비게이션 프레임워크입니다.
RxFlow와 동일한 API 구조와 로직을 제공하면서, RxSwift 의존성 없이 Swift Concurrency만 사용합니다.

### 주요 특징

- ✅ RxFlow와 동일한 API 설계 (Step, Stepper, Flow, FlowContributor, FlowCoordinator)
- ✅ RxSwift 의존성 제거, Swift Concurrency (async/await, AsyncStream) 사용
- ✅ 부모-자식 FlowCoordinator 관계 지원
- ✅ forwardToCurrentFlow, forwardToParentFlow, end 지원
- ✅ Flows.use(when:) 유틸리티 지원
- ✅ 선언적이고 테스트 가능한 네비게이션
- ✅ 타입 안전성 보장

---

## 핵심 개념

RxFlow와 동일한 6가지 핵심 개념을 사용합니다:

1. Flow: 앱의 네비게이션 영역을 정의
2. Step: 네비게이션 상태를 표현
3. Stepper: Step을 방출하는 주체
4. Presentable: 화면에 표시될 수 있는 것 (UIViewController, Flow)
5. FlowContributor: 다음 Presentable/Stepper 조합을 정의
6. FlowCoordinator: Flow와 Stepper를 조율

---

## 모듈 구조

```
AsyncFlow/
├── Sources/
│   ├── Core/
│   │   ├── Step.swift           # Step 프로토콜, NoneStep
│   │   ├── Stepper.swift        # Stepper 프로토콜, AsyncPassthroughSubject
│   │   ├── Presentable.swift    # Presentable 프로토콜
│   │   ├── Flow.swift           # Flow 프로토콜
│   │   ├── FlowContributor.swift # FlowContributor, FlowContributors
│   │   └── FlowCoordinator.swift # FlowCoordinator
│   ├── Integration/
│   │   ├── UIViewController+Presentable.swift
│   │   ├── UIWindow+Presentable.swift
│   │   ├── NSViewController+Presentable.swift
│   │   └── NSWindow+Presentable.swift
│   ├── Utilities/
│   │   ├── OneStepper.swift     # 초기 Step 하나만 방출
│   │   ├── DefaultStepper.swift # NoneStep 방출
│   │   ├── CompositeStepper.swift # 여러 Stepper 조합
│   │   └── Flows.swift          # Flows.use(when:) 유틸리티
│   └── Testing/
│       ├── FlowTestStore.swift
│       └── MockStepper.swift
└── Tests/
```

---

## 사용법

### 1. Step 정의

```swift
enum AppStep: Step {
    case home
    case login
    case movieList
    case movieDetail(id: Int)
}
```

### 2. Stepper 구현 (ViewModel)

```swift
@MainActor
final class MovieListViewModel: Stepper {
    let steps = AsyncPassthroughSubject<Step>()
    
    var initialStep: Step {
        AppStep.movieList
    }
    
    func selectMovie(id: Int) {
        steps.send(AppStep.movieDetail(id: id))
    }
}
```

### 3. Flow 구현

```swift
final class MovieFlow: Flow {
    var root: Presentable { navigationController }
    private let navigationController = UINavigationController()
    
    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? AppStep else { return .none }
        
        switch step {
        case .movieList:
            return navigateToMovieList()
        case .movieDetail(let id):
            return navigateToMovieDetail(id: id)
        default:
            return .none
        }
    }
    
    private func navigateToMovieList() -> FlowContributors {
        let viewModel = MovieListViewModel()
        let viewController = MovieListViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }
    
    private func navigateToMovieDetail(id: Int) -> FlowContributors {
        let viewModel = MovieDetailViewModel(id: id)
        let viewController = MovieDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        
        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }
}
```

### 4. 앱 시작

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    let coordinator = FlowCoordinator()
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        guard let window = self.window else { return false }
        
        // 네비게이션 이벤트 로깅
        Task {
            for await event in coordinator.didNavigate {
                print("Did navigate: \(event.flowType) -> \(event.stepDescription)")
            }
        }
        
        let appFlow = AppFlow(window: window)
        let appStepper = OneStepper(withSingleStep: AppStep.home)
        
        coordinator.coordinate(flow: appFlow, with: appStepper)
        
        return true
    }
}
```

---

## 자식 Flow 시작

```swift
private func navigateToSettings() -> FlowContributors {
    let settingsFlow = SettingsFlow()
    let settingsStepper = OneStepper(withSingleStep: SettingsStep.main)
    
    Flows.use(settingsFlow, when: .ready) { [weak self] root in
        self?.navigationController.present(root, animated: true)
    }
    
    return .one(flowContributor: .contribute(
        withNextPresentable: settingsFlow,
        withNextStepper: settingsStepper
    ))
}
```

---

## FlowContributor 종류

### contribute
Presentable과 Stepper를 연결하여 현재 Flow에 기여

```swift
.one(flowContributor: .contribute(
    withNextPresentable: viewController,
    withNextStepper: viewModel,
    allowStepWhenNotPresented: false,  // 기본값
    allowStepWhenDismissed: false       // 기본값
))
```

### forwardToCurrentFlow
현재 Flow에 Step을 즉시 전달

```swift
.one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.home))
```

### forwardToParentFlow
부모 Flow에 Step을 전달

```swift
.one(flowContributor: .forwardToParentFlow(withStep: AppStep.logout))
```

### end
현재 Flow 종료 및 부모 Flow에 Step 전달

```swift
.end(forwardToParentFlowWithStep: AppStep.settingsComplete)
```

---

## Step 필터링 (adapt)

```swift
func adapt(step: Step) async -> Step {
    guard let appStep = step as? AppStep else { return step }
    
    switch appStep {
    case .movieDetail:
        if await AuthService.shared.isLoggedIn() {
            return step
        } else {
            return AppStep.login
        }
    default:
        return step
    }
}
```

---

## DeepLink 처리

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    // DeepLink Step 전달 (모든 자식 Flow에도 전파됨)
    coordinator.navigate(to: AppStep.movieDetail(id: 12345))
}
```

---

## 테스트

```swift
@Test
func testFlowNavigation() async {
    let flow = MovieFlow()
    let store = FlowTestStore(flow: flow)
    
    let contributors = store.navigate(to: AppStep.movieList)
    
    #expect(store.steps.count == 1)
    
    if case .one(.contribute(let presentable, let stepper, _, _)) = contributors {
        #expect(presentable is UIViewController)
        #expect(stepper is MovieListViewModel)
    }
}
```

---

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncFlow", from: "1.0.0")
]
```

### Tuist

```swift
// Dependencies.swift
.package(url: "https://github.com/Jimmy-Jung/AsyncFlow", from: "1.0.0")

// Project.swift
dependencies: [
    .external(name: "AsyncFlow")
]
```

---

## RxFlow와의 비교

| 기능 | RxFlow | AsyncFlow |
|------|--------|-----------|
| Step | Protocol | Protocol |
| Stepper | PublishRelay | AsyncPassthroughSubject |
| Flow | Protocol | Protocol |
| FlowContributor | Enum | Enum |
| FlowCoordinator | Class | Class |
| adapt(step:) | Single<Step> | async Step |
| navigate(to:) | FlowContributors | FlowContributors |
| Flows.use(when:) | ✅ | ✅ |
| 부모-자식 관계 | ✅ | ✅ |
| forwardToParentFlow | ✅ | ✅ |
| end | ✅ | ✅ |

---

## 라이선스

MIT License
