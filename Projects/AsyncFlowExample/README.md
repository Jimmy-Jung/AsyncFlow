# AsyncFlowExample

AsyncFlow 프레임워크를 사용한 실전 예제 앱

## 개요

이 프로젝트는 AsyncFlow와 AsyncViewModel을 함께 사용하여 영화 앱을 구현한 예제입니다.

### 주요 구현 내용

- ✅ AsyncFlow 네비게이션 패턴
- ✅ AsyncViewModel 단방향 데이터 흐름
- ✅ Tuist 프로젝트 관리
- ✅ Swift 6 Concurrency

---

## 프로젝트 구조

```
AsyncFlowExample/
├── Sources/
│   ├── App/                        # 앱 진입점
│   │   └── AppDelegate.swift
│   ├── Models/                     # 데이터 모델
│   │   └── Movie.swift
│   ├── Steps/                      # 네비게이션 Step
│   │   └── MovieStep.swift
│   ├── Flows/                      # Flow 정의
│   │   ├── AppFlow.swift
│   │   └── MovieFlow.swift
│   ├── ViewModels/                 # AsyncViewModel
│   │   ├── MovieListViewModel.swift
│   │   └── MovieDetailViewModel.swift
│   └── Views/                      # UIViewController
│       ├── MovieListViewController.swift
│       └── MovieDetailViewController.swift
└── Resources/
    └── LaunchScreen.storyboard
```

---

## 핵심 구현 패턴

### 1. Step 정의

```swift
enum MovieStep: Step {
    case appLaunch
    case movieList
    case movieDetail(id: Int)
    case search
}
```

### 2. ViewModel (Stepper)

```swift
@MainActor
final class MovieListViewModel: ObservableObject, Stepper {
    @StepEmitter var stepEmitter: StepEmitter<MovieStep>
    @Published var state = State()
    
    func send(_ input: Input) {
        switch input {
        case let .movieTapped(id):
            emit(.movieDetail(id: id))  // Step 방출!
        }
    }
}
```

### 3. Flow 정의

```swift
final class MovieFlow: Flow {
    func navigate(to step: MovieStep) async -> FlowContributors {
        switch step {
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
        
        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }
}
```

### 4. AppDelegate에서 조율 시작

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let coordinator = FlowCoordinator()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let appFlow = AppFlow(window: window!)
        let appStepper = OneStepper(MovieStep.appLaunch)
        coordinator.coordinate(flow: appFlow, with: appStepper)
        
        return true
    }
}
```

---

## 빌드 및 실행

### 1. Tuist 설치

```bash
curl -Ls https://install.tuist.io | bash
```

### 2. 의존성 설치

```bash
cd /Users/jimmy/Documents/GitHub/AsyncFlow
tuist install
```

### 3. 프로젝트 생성

```bash
tuist generate
```

### 4. Xcode에서 실행

```bash
open AsyncFlowExample.xcworkspace
```

---

## 학습 포인트

### AsyncFlow 패턴

1. **Step**: 네비게이션 의도를 표현 (화면과 독립적)
2. **Stepper**: Step을 방출 (ViewModel이 담당)
3. **Flow**: Step을 네비게이션 액션으로 변환
4. **FlowCoordinator**: 전체 네비게이션 조율

### AsyncViewModel 패턴

1. **Input → Action 변환**: `transform(_:)`
2. **State 변경**: `reduce(state:action:)`
3. **비동기 작업**: `AsyncEffect`
4. **네비게이션**: `emit(_:)`로 Step 방출

### 통합 패턴

```
User Tap
   ↓
ViewModel.send(.movieTapped)
   ↓
transform: Input → Action
   ↓
reduce: Action → State + Step
   ↓
emit(.movieDetail(id))
   ↓
FlowCoordinator
   ↓
Flow.navigate(to:)
   ↓
Push MovieDetailViewController
```

---

## 의존성

- **AsyncFlow**: 네비게이션 프레임워크 (로컬 패키지)
- **AsyncViewModel**: 단방향 데이터 흐름 (외부 패키지)

```swift
// Tuist/Package.swift
dependencies: [
    .package(url: "https://github.com/Jimmy-Jung/AsyncViewModel", from: "1.2.0")
]

// Project.swift
dependencies: [
    .package(product: "AsyncFlow", type: .runtime),
    .external(name: "AsyncViewModel")
]
```

---

## 다음 단계

1. **기능 추가**: 검색, 즐겨찾기, 상세 정보 등
2. **테스트 작성**: FlowTestStore, AsyncTestStore 활용
3. **CI/CD 구성**: GitHub Actions + Tuist
4. **성능 최적화**: 이미지 캐싱, 페이지네이션 등

---

## 참고 문서

- [AsyncFlow 아키텍처 가이드](../../ARCHITECTURE.md)
- [AsyncViewModel 문서](https://github.com/Jimmy-Jung/AsyncViewModel)
- [Tuist 가이드](https://docs.tuist.io)

---

**Made with ❤️ and ☕ in Seoul, Korea**

