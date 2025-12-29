# AsyncFlow

Swift Concurrency 기반 iOS 네비게이션 프레임워크

## 개요

AsyncFlow는 RxFlow에서 영감을 받아 Swift Concurrency로 재설계한 네비게이션 프레임워크입니다.

### 주요 특징

- ✅ RxSwift 의존성 제거, Swift Concurrency만 사용
- ✅ AsyncViewModel과 자연스러운 통합
- ✅ 선언적이고 테스트 가능한 네비게이션
- ✅ 타입 안전성 보장

---

## 모듈 구조

```
AsyncFlow/
├── Sources/
│   ├── Core/                    # 핵심 프로토콜
│   │   ├── Step.swift
│   │   ├── Stepper.swift
│   │   ├── Presentable.swift
│   │   ├── Flow.swift
│   │   ├── FlowContributor.swift
│   │   └── FlowCoordinator.swift
│   ├── Integration/             # 플랫폼 통합
│   │   └── UIViewController+Presentable.swift
│   ├── Utilities/               # 헬퍼
│   │   ├── AsyncStreamBridge.swift
│   │   ├── OneStepper.swift
│   │   └── CompositeStepper.swift
│   └── Testing/                 # 테스트 도구
│       ├── FlowTestStore.swift
│       └── MockStepper.swift
└── Tests/
    └── AsyncFlowTests/
```

---

## 핵심 개념

### 1. Step (네비게이션 의도)

```swift
enum MovieStep: Step {
    case movieList
    case movieDetail(id: Int)
}
```

### 2. Stepper (Step 방출자)

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

### 3. Flow (Step → 네비게이션 변환)

```swift
final class MovieFlow: Flow {
    func navigate(to step: MovieStep) async -> FlowContributors {
        switch step {
        case .movieDetail(let id):
            return navigateToMovieDetail(id: id)
        }
    }
}
```

---

## 설치

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

## 문서

- [프로젝트 README](../../README.md)
- [아키텍처 가이드](../../ARCHITECTURE.md)
- [예제 앱](../AsyncFlowExample/)

---

## 라이선스

MIT License

