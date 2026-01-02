# 변경 이력

AsyncFlow의 모든 주요 변경사항은 이 파일에 문서화됩니다.

이 문서는 [Keep a Changelog](https://keepachangelog.com/ko/1.0.0/) 형식을 따르며,
[Semantic Versioning](https://semver.org/lang/ko/)을 준수합니다.

## [1.0.0] - 2025-01-02

### 추가

- AsyncFlow 최초 릴리스
- Swift Concurrency 기반 네비게이션 프레임워크
- 네비게이션 의도 표현을 위한 `Step` 프로토콜
- Step 방출을 위한 `FlowStepper` 프로토콜
- 화면 추상화를 위한 `Presentable` 프로토콜
- 네비게이션 영역 정의를 위한 `Flow` 프로토콜
- Stepper와 Presentable 연결을 위한 `FlowContributor`
- 네비게이션 조율을 위한 `FlowCoordinator`
- Step 방출을 위한 `@Steps` 프로퍼티 래퍼
- Step 스트리밍을 위한 `AsyncPassthroughSubject`
- 버퍼링된 Step 스트리밍을 위한 `AsyncReplaySubject`
- 내장 유틸리티 타입:
  - `OneStepper` - 단일 초기 Step 방출
  - `CompositeStepper` - 여러 Stepper 조합
  - `NoneStep` - 아무 작업도 수행하지 않는 Step
- 테스트 유틸리티:
  - Flow 테스트를 위한 `FlowTestStore`
  - Stepper 테스트를 위한 `MockStepper`
- `navigate(to:)` 주입을 통한 딥링크 지원
- 권한 체크를 위한 `adapt(step:)`를 통한 Step 적응
- 네비게이션 이벤트 스트림 (`willNavigate`, `didNavigate`)
- 부모-자식 FlowCoordinator 관계
- 자동 Task 정리 및 메모리 관리
- iOS 15.0+ 및 macOS 12.0+ 지원
- DocC를 통한 완전한 문서화
- 핵심 기능을 보여주는 예제 앱
- Swift Testing을 사용한 포괄적인 테스트 스위트

### 문서

- 완전한 API 문서
- 빠른 시작 가이드
- 핵심 개념 설명
- 고급 기능 가이드
- 실전 사용법을 보여주는 예제 앱
- 테스트 가이드
- 기여 가이드라인

---

## [미배포]

### 계획

- visionOS 지원
- watchOS 지원
- 네비게이션 디버깅 도구
- Coordinator 간 통신 API
- Flow 애니메이션 커스터마이징

---

[1.0.0]: https://github.com/Jimmy-Jung/AsyncFlow/releases/tag/1.0.0

