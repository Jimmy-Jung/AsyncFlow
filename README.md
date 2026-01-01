# AsyncFlow

Swift Concurrency 기반 iOS 네비게이션 프레임워크

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B%20%7C%20macOS%2012%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/Jimmy-Jung/AsyncFlow/actions/workflows/ci.yml/badge.svg)](https://github.com/Jimmy-Jung/AsyncFlow/actions/workflows/ci.yml)

## 개요

AsyncFlow는 [RxFlow](https://github.com/RxSwiftCommunity/RxFlow)에서 영감을 받아 Swift Concurrency로 재설계한 네비게이션 프레임워크입니다.

### RxFlow와의 차이점

| 특징 | RxFlow | AsyncFlow |
|------|--------|-----------|
| 비동기 처리 | RxSwift Observable | Swift Concurrency (async/await) |
| Step 스트림 | `PublishRelay<Step>` | `AsyncPassthroughSubject<Step>` (버퍼링 지원) |
| Step 타입 | Generic `StepType` | Type-erased `Step` 프로토콜 |
| 스레드 안전성 | subscribeOn/observeOn | `@MainActor` |
| 외부 의존성 | RxSwift, RxRelay | 없음 (Swift 표준만 사용) |
| 메모리 관리 | DisposeBag | Task 자동 취소 |
| 프로젝트 관리 | CocoaPods/Carthage | Tuist |
| Property Wrapper | 없음 | `@Steps` 제공 |
| FlowContributor | Generic | Type-erased |

### 주요 특징

- ✅ **RxFlow와 동일한 로직**: RxFlow의 모든 패턴을 Swift Concurrency로 구현
- ✅ **RxSwift 의존성 제거**: Swift Concurrency만 사용
- ✅ **Type-erased Step**: Generic 제약 없이 유연한 네비게이션
- ✅ **버퍼링 지원**: 구독 전 Step도 안전하게 처리 (ReplaySubject 패턴)
- ✅ **Property Wrapper**: `@Steps`로 간결한 FlowStepper 선언
- ✅ **FlowContributor 패턴**: `.forwardToCurrentFlow`, `.forwardToParentFlow`, `.end` 지원
- ✅ **[AsyncViewModel](https://github.com/Jimmy-Jung/AsyncViewModel) 통합**: 자연스러운 단방향 데이터 흐름
- ✅ **선언적이고 테스트 가능**: Swift Testing 프레임워크 지원
- ✅ **Deep Link, 권한 체크**: 고급 기능 지원
- ✅ **Tuist 기반**: 모듈화된 프로젝트 관리

---

## 프로젝트 구조

```
AsyncFlow/
├── Tuist.swift                          # Tuist 전역 설정
├── Workspace.swift                      # Workspace 정의
├── Tuist/
│   ├── Package.swift                    # 외부 의존성 (AsyncViewModel)
│   └── ProjectDescriptionHelpers/
│       └── Project+Templates.swift      # 재사용 템플릿
│
├── Projects/
│   ├── AsyncFlow/                       # 🔥 AsyncFlow 라이브러리
│   │   ├── Project.swift
│   │   ├── Sources/
│   │   │   ├── Core/                    # 핵심 프로토콜
│   │   │   ├── Integration/             # 플랫폼 통합
│   │   │   ├── Utilities/               # 헬퍼
│   │   │   └── Testing/                 # 테스트 도구
│   │   └── Tests/
│   │
│   └── AsyncFlowExample/                # 📱 예제 앱
│       ├── Project.swift
│       ├── Sources/
│       │   ├── App/                     # 앱 진입점
│       │   ├── Models/                  # 데이터 모델
│       │   ├── Steps/                   # 네비게이션 Step
│       │   ├── Flows/                   # Flow 정의
│       │   ├── ViewModels/              # AsyncViewModel
│       │   └── Views/                   # UIViewController
│       └── Resources/
│
├── README.md                            # 프로젝트 소개
└── LICENSE                              # MIT 라이선스
```

---

## 설치

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncFlow", from: "1.0.0")
]
```

### Tuist

```swift
// Tuist/Package.swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncFlow", from: "1.0.0")
]

// Project.swift
dependencies: [
    .external(name: "AsyncFlow")
]
```

> **Note**: 1.0.0 릴리스 전에는 특정 커밋이나 브랜치를 사용하세요:
> ```swift
> .package(url: "https://github.com/Jimmy-Jung/AsyncFlow", branch: "main")
> ```

---

## 핵심 개념

AsyncFlow는 7가지 핵심 타입으로 구성됩니다:

### 1. Step

네비게이션 의도를 표현하는 프로토콜

```swift
enum MovieStep: Step {
    case movieList
    case movieDetail(id: Int)
    case castDetail(id: Int)
    case unauthorized
}
```

### 2. FlowStepper

Step을 방출하는 주체 (주로 ViewModel)

```swift
@MainActor
final class MovieListViewModel: ObservableObject, FlowStepper {
    @Steps var steps  // Property wrapper로 간단하게 선언
    
    @Published var state = State()
    
    var initialStep: Step {
        NoneStep()  // 기본값: 초기 Step 없음
    }
    
    func readyToEmitSteps() {
        // FlowCoordinator가 FlowStepper를 구독할 때 호출됨
    }
    
    enum Input: Sendable {
        case movieTapped(id: Int)
    }
    
    struct State: Equatable, Sendable {
        var movies: [Movie] = []
    }
    
    func send(_ input: Input) {
        switch input {
        case let .movieTapped(id):
            steps.send(MovieStep.movieDetail(id: id))  // ← Step 방출!
        }
    }
}
```

### 3. Presentable

화면에 표시될 수 있는 것 (UIViewController, Flow)

```swift
extension UIViewController: Presentable {}  // 자동 구현됨
```

### 4. Flow

네비게이션 영역 정의 및 Step → 네비게이션 액션 변환

```swift
@MainActor
final class MovieFlow: Flow {
    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()
    
    // Step 필터링/변환 (선택사항)
    func adapt(step: Step) async -> Step {
        guard let movieStep = step as? MovieStep else { return step }
        // 권한 체크, 인증 체크 등 수행 가능
        return movieStep
    }
    
    // 네비게이션 수행
    func navigate(to step: Step) -> FlowContributors {
        guard let movieStep = step as? MovieStep else { return .none }
        
        switch movieStep {
        case .movieList:
            return navigateToMovieList()
        case .movieDetail(let id):
            return navigateToMovieDetail(id: id)
        }
    }
    
    private func navigateToMovieList() -> FlowContributors {
        let viewModel = MovieListViewModel()
        let viewController = MovieListViewController(viewModel: viewModel)
        navigationController.setViewControllers([viewController], animated: false)
        
        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }
}
```

### 5. FlowContributor

다음 FlowStepper와 Presentable 연결

```swift
// 단일 Contributor
return .one(flowContributor: .contribute(
    withNextPresentable: viewController,
    withNextStepper: viewModel
))

// 여러 Contributor (예: TabBarController)
return .multiple(flowContributors: [
    .contribute(
        withNextPresentable: dashboardFlow,
        withNextStepper: dashboardStepper
    ),
    .contribute(
        withNextPresentable: settingsFlow,
        withNextStepper: settingsStepper
    )
])

// 현재 Flow에 Step 전달
return .one(flowContributor: .forwardToCurrentFlow(withStep: MovieStep.movieList))

// 부모 Flow에 Step 전달
return .one(flowContributor: .forwardToParentFlow(withStep: MovieStep.logout))

// Flow 종료 및 부모에 Step 전달
return .end(forwardToParentFlowWithStep: MovieStep.main)
```

### 6. FlowCoordinator

전체 네비게이션 조율자

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let coordinator = FlowCoordinator()
    var appFlow: AppFlow?  // Strong reference 유지
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let appFlow = AppFlow(window: window!)
        self.appFlow = appFlow  // Strong reference 저장
        
        let appStepper = OneStepper(withSingleStep: MovieStep.appLaunch)
        coordinator.coordinate(flow: appFlow, with: appStepper)
        
        return true
    }
}
```

### 7. OneStepper & CompositeStepper

초기 Step을 방출하는 유틸리티 FlowStepper

```swift
// 단일 Step 방출
let stepper = OneStepper(withSingleStep: MovieStep.movieList)

// 여러 FlowStepper 조합
let stepper1 = OneStepper(withSingleStep: MovieStep.movieList)
let stepper2 = OneStepper(withSingleStep: MovieStep.watchedList)
let compositeStepper = CompositeStepper(steppers: [stepper1, stepper2])
```

---

## 빌드 및 실행

### 1. Tuist 설치

```bash
curl -Ls https://install.tuist.io | bash
```

### 2. 프로젝트 생성

```bash
cd AsyncFlow
tuist install  # 외부 의존성 설치
tuist generate  # Xcode 프로젝트 생성
```

### 3. Xcode에서 실행

```bash
open AsyncFlow.xcworkspace
```

또는 Tuist로 직접 빌드:

```bash
tuist build AsyncFlowExample
tuist run AsyncFlowExample
```

---

## AsyncViewModel 통합

AsyncFlow는 AsyncViewModel과 자연스럽게 통합됩니다.

```swift
@AsyncViewModel
final class LoginViewModel: ObservableObject, FlowStepper {
    @Steps var steps  // Property wrapper로 선언
    
    var initialStep: Step {
        NoneStep()  // 기본값
    }
    
    func readyToEmitSteps() {}
    
    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .login(let email, let password):
            state.isLoading = true
            return [
                .run(id: .login) {
                    try await authService.login(email, password)
                    return .loginSuccess
                }
            ]
        case .loginSuccess:
            state.isLoading = false
            steps.send(AuthStep.loginCompleted)  // ← Step 방출!
            return []
        }
    }
}
```

`FlowStepper` 프로토콜을 채택하면 `@Steps` property wrapper를 사용하여 Step을 방출할 수 있습니다.

---

## 고급 사용법

### 자식 Flow 사용

```swift
@MainActor
final class AppFlow: Flow {
    var root: any Presentable { window }
    private let window: UIWindow
    
    func navigate(to step: Step) -> FlowContributors {
        guard let appStep = step as? AppStep else { return .none }
        
        switch appStep {
        case .auth:
            return navigateToAuth()
        case .main:
            return navigateToMain()
        }
    }
    
    private func navigateToAuth() -> FlowContributors {
        let authFlow = AuthFlow()
        window.rootViewController = authFlow.root.viewController
        window.makeKeyAndVisible()
        
        // 자식 Flow를 Contributor로 반환 (자동으로 자식 FlowCoordinator 생성)
        return .one(flowContributor: .contribute(
            withNextPresentable: authFlow,
            withNextStepper: OneStepper(withSingleStep: AppStep.auth(.loginRequired))
        ))
    }
}
```

### 현재 Flow에 Step 전달

```swift
private func navigateToLaunch() -> FlowContributors {
    if isLoggedIn {
        return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.main))
    } else {
        return .one(flowContributor: .forwardToCurrentFlow(withStep: AppStep.auth(.loginRequired)))
    }
}
```

### 부모 Flow에 Step 전달

```swift
@MainActor
final class AuthFlow: Flow {
    func navigate(to step: Step) -> FlowContributors {
        guard let appStep = step as? AppStep else { return .none }
        
        switch appStep {
        case .auth(.loginSuccess):
            // AuthFlow 종료 및 부모 Flow에 main step 전달
            return .end(forwardToParentFlowWithStep: AppStep.main)
        }
    }
}
```

### Step 필터링 (adapt)

```swift
func adapt(step: Step) async -> Step {
    guard let appStep = step as? AppStep else { return step }
    
    // 권한 체크
    if case .dashboard(.featureDetail(let feature)) = appStep,
       feature.requiresPermission {
        let hasPermission = await permissionService.checkPermission(.camera)
        if !hasPermission {
            return AppStep.dashboard(.permissionRequired(
                message: "권한이 필요합니다",
                permission: .camera
            ))
        }
    }
    
    return appStep
}
```

### 여러 Flow 동기화

```swift
import AsyncFlow

// 모든 Flow가 ready될 때까지 대기
Flows.use(dashboardFlow, settingsFlow, when: .allReady) { dashboardRoot, settingsRoot in
    // 두 Flow의 root ViewController가 모두 준비됨
    tabBarController.setViewControllers([dashboardRoot, settingsRoot], animated: false)
}
```

---

## 예제 앱

[AsyncFlowExample](Projects/AsyncFlowExample/) 프로젝트에서 실전 사용법을 확인할 수 있습니다.

### 데이터 흐름

```mermaid
sequenceDiagram
    participant User
    participant View
    participant ViewModel
    participant Coordinator as FlowCoordinator
    participant Flow
    
    User->>View: Tap Movie Cell
    View->>ViewModel: send(.movieTapped(id: 1))
    ViewModel->>ViewModel: steps.send(.movieDetail(id: 1))
    ViewModel->>Coordinator: Step 방출
    Coordinator->>Flow: adapt(step: .movieDetail(id: 1))
    Coordinator->>Flow: navigate(to: .movieDetail(id: 1))
    Flow->>Flow: navigateToMovieDetail(id: 1)
    Flow->>Flow: Push MovieDetailViewController
    Flow-->>Coordinator: .one(.contribute(withNextPresentable:withNextStepper:))
    Coordinator->>ViewModel: 새로운 FlowStepper 구독 (initialStep 처리)
```

---

## 테스트

### Flow 테스트

```swift
@Test
@MainActor
func testMovieFlowNavigation() async {
    let flow = MovieFlow()
    let store = FlowTestStore(flow: flow)
    
    let contributors = store.navigate(to: MovieStep.movieList)
    
    #expect(store.steps == [MovieStep.movieList])
    
    if case .one(flowContributor: .contribute(let presentable, let stepper)) = contributors {
        #expect(presentable.viewController is MovieListViewController)
        #expect(stepper is MovieListViewModel)
    }
}
```

### FlowStepper 테스트

```swift
@Test
@MainActor
func testStepEmission() async throws {
    let mockStepper = MockStepper()
    mockStepper.setInitialStep(MovieStep.movieList)
    
    let collectionTask = Task {
        var steps: [Step] = []
        for await step in mockStepper.steps.stream {
            if let movieStep = step as? MovieStep {
                steps.append(movieStep)
            }
            if steps.count == 2 { break }
        }
        return steps
    }
    
    // 구독 시작 대기
    await Task.yield()
    
    mockStepper.emit(MovieStep.movieList)
    mockStepper.emit(MovieStep.movieDetail(id: 1))
    
    let receivedSteps = await collectionTask.value
    
    #expect(receivedSteps.count == 2)
    #expect((receivedSteps[0] as? MovieStep) == .movieList)
    #expect((receivedSteps[1] as? MovieStep) == .movieDetail(id: 1))
}
```

---

## 문서

- [AsyncFlow Library](Projects/AsyncFlow/) - 라이브러리 코어
- [AsyncFlowExample](Projects/AsyncFlowExample/) - 예제 앱

---

## 요구사항

- iOS 15.0+
- macOS 12.0+
- Swift 6.0+
- Xcode 16.0+

---

## 라이선스

AsyncFlow는 MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

## 크레딧

AsyncFlow는 다음 프로젝트에서 영감을 받았습니다:

- [RxFlow](https://github.com/RxSwiftCommunity/RxFlow) - Reactive Flow Coordinator pattern
- [AsyncViewModel](https://github.com/Jimmy-Jung/AsyncViewModel) - 단방향 데이터 흐름
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) - Effect 패턴

---

**Made with ❤️ and ☕ in Seoul, Korea**
