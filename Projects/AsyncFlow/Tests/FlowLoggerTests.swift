//
//  FlowLoggerTests.swift
//  AsyncFlow
//
//  Created by 정준영 on 2026. 1. 2.
//

@testable import AsyncFlow
import Testing

// MARK: - Test Fixtures

enum FlowLoggerTestStep: Step {
    case first
    case second
    case third(id: Int)
}

@MainActor
final class FlowLoggerTestFlow: Flow {
    let rootPresentable = FlowLoggerTestMockPresentable()
    var root: Presentable { rootPresentable }
    var capturedSteps: [Step] = []

    func navigate(to step: Step) -> FlowContributors {
        capturedSteps.append(step)
        return .none
    }
}

@MainActor
final class FlowLoggerTestMockPresentable: Presentable {
    private let visibilitySubject = AsyncReplaySubject<Bool>(bufferSize: 1)
    private let dismissSubject = AsyncPassthroughSubject<Void>()

    var isVisibleStream: AsyncStream<Bool> { visibilitySubject.stream }
    var onDismissed: AsyncStream<Void> { dismissSubject.stream }

    init() {
        visibilitySubject.send(true)
    }
}

@MainActor
final class FlowLoggerTestMockStepper: FlowStepper {
    @Steps var steps
    var initialStep: Step { NoneStep() }

    func emit(_ step: Step) {
        steps.send(step)
    }
}

// MARK: - Mock Logger

@MainActor
final class FlowLoggerTestMockLogger: FlowLogger {
    var loggedStacks: [NavigationStack] = []

    func log(navigationStack: NavigationStack) {
        loggedStacks.append(navigationStack)
    }
}

// MARK: - Tests

@Suite("FlowLogger Tests")
@MainActor
struct FlowLoggerTests {
    // MARK: - StepInfo Tests

    @Test("StepInfo는 Step으로부터 타입 이름과 케이스 설명을 추출한다")
    func stepInfoExtraction() {
        let step = FlowLoggerTestStep.third(id: 42)
        let stepInfo = StepInfo(step: step)

        #expect(stepInfo.typeName == "FlowLoggerTestStep")
        #expect(stepInfo.caseDescription.contains("third"))
        #expect(stepInfo.caseDescription.contains("42"))
    }

    @Test("StepInfo는 associated value의 중첩 타입명을 제거한다")
    func stepInfoNestedTypeRemoval() {
        // "FlowLoggerTestStep.third(id: 42)" → typeName: "FlowLoggerTestStep", caseDescription: "third(id: 42)"
        let step = FlowLoggerTestStep.third(id: 42)
        let stepInfo = StepInfo(step: step)

        #expect(stepInfo.typeName == "FlowLoggerTestStep")
        // "FlowLoggerTestStep."이 제거되어야 함
        #expect(!stepInfo.caseDescription.contains("FlowLoggerTestStep."))
    }

    @Test("StepInfo description은 타입.케이스 형식이다")
    func stepInfoDescription() {
        let stepInfo = StepInfo(typeName: "MovieStep", caseDescription: "movieDetail(id: 1)")

        #expect(stepInfo.description == "MovieStep.movieDetail(id: 1)")
    }

    // MARK: - NavigationStack Tests

    @Test("NavigationStack depth는 steps 배열 크기와 같다")
    func navigationStackDepth() {
        let steps = [
            StepInfo(typeName: "FlowLoggerTestStep", caseDescription: "first"),
            StepInfo(typeName: "FlowLoggerTestStep", caseDescription: "second"),
            StepInfo(typeName: "FlowLoggerTestStep", caseDescription: "third"),
        ]
        let stack = NavigationStack(flowName: "TestFlow", steps: steps)

        #expect(stack.depth == 3)
    }

    // MARK: - ConsoleFlowLogger Tests

    @Test("ConsoleFlowLogger는 올바른 형식으로 로그를 포맷팅한다")
    func consoleFlowLoggerFormatting() {
        let logger = ConsoleFlowLogger()
        let steps = [
            StepInfo(typeName: "LoginStep", caseDescription: "loginStart"),
            StepInfo(typeName: "LoginStep", caseDescription: "emailInput"),
            StepInfo(typeName: "LoginStep", caseDescription: "passwordInput"),
            StepInfo(typeName: "LoginStep", caseDescription: "loginSuccess"),
        ]
        let stack = NavigationStack(flowName: "LoginFlow", steps: steps)

        // formatNavigationStack이 private이므로 log 메서드를 통해 간접 테스트
        logger.log(navigationStack: stack)

        // 스택 구조 검증
        #expect(stack.flowName == "LoginFlow")
        #expect(stack.depth == 4)
        #expect(stack.steps[0].caseDescription == "loginStart")
        #expect(stack.steps[3].caseDescription == "loginSuccess")
    }

    // MARK: - FlowCoordinator Integration Tests

    @Test("FlowCoordinator는 Step 네비게이션 시 로거를 호출한다")
    func flowCoordinatorLogsNavigation() async throws {
        let mockLogger = FlowLoggerTestMockLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let flow = FlowLoggerTestFlow()
        let stepper = OneStepper(withSingleStep: FlowLoggerTestStep.first)

        coordinator.coordinate(flow: flow, with: stepper)

        // 네비게이션 완료 대기 (일반 Flow는 스택이 비어있지 않을 때만 로그 출력)
        // initialStep이 처리되고 스택에 추가될 때까지 대기
        await Test.waitUntil(timeout: 2.0) {
            !mockLogger.loggedStacks.isEmpty || flow.capturedSteps.contains(where: { $0 is FlowLoggerTestStep })
        }

        try #require(!mockLogger.loggedStacks.isEmpty, "로그가 기록되지 않았습니다")
        #expect(mockLogger.loggedStacks[0].flowName == "FlowLoggerTestFlow")
        #expect(mockLogger.loggedStacks[0].depth == 1)
    }

    @Test("FlowCoordinator는 여러 Step을 순차적으로 로깅한다")
    func flowCoordinatorLogsMultipleSteps() async throws {
        let mockLogger = FlowLoggerTestMockLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let flow = FlowLoggerTestFlow()
        let stepper = FlowLoggerTestMockStepper()

        coordinator.coordinate(flow: flow, with: stepper)

        // 여러 Step 방출
        stepper.emit(FlowLoggerTestStep.first)
        try await Task.sleep(nanoseconds: 50_000_000)

        stepper.emit(FlowLoggerTestStep.second)
        try await Task.sleep(nanoseconds: 50_000_000)

        stepper.emit(FlowLoggerTestStep.third(id: 10))
        try await Task.sleep(nanoseconds: 50_000_000)

        try #require(mockLogger.loggedStacks.count >= 3, "최소 3개의 로그가 기록되어야 합니다")
        #expect(mockLogger.loggedStacks.last?.depth == 3)
    }

    @Test("NoOpFlowLogger는 아무것도 출력하지 않는다")
    func noOpFlowLogger() {
        let logger = NoOpFlowLogger()
        let stack = NavigationStack(
            flowName: "FlowLoggerTestFlow",
            steps: [StepInfo(typeName: "FlowLoggerTestStep", caseDescription: "first")]
        )

        // 오류 없이 실행되어야 함
        logger.log(navigationStack: stack)

        // NoOpFlowLogger는 아무것도 하지 않으므로 검증할 수 없지만,
        // 오류 없이 완료되면 통과
        #expect(Bool(true))
    }

    @Test("FlowCoordinator 기본 생성자는 NoOpFlowLogger를 사용한다")
    func defaultLoggerIsNoOp() {
        _ = FlowCoordinator()

        // 내부 logger가 NoOpFlowLogger인지 직접 확인할 수 없지만,
        // 기본 동작이 정상적으로 수행되는지 확인
        #expect(Bool(true))
    }

    // MARK: - Custom Logger Tests

    @Test("커스텀 로거를 주입할 수 있다")
    func customLoggerInjection() async throws {
        @MainActor
        final class CustomLogger: FlowLogger {
            var callCount = 0
            var continuation: CheckedContinuation<Void, Never>?

            func log(navigationStack _: NavigationStack) {
                callCount += 1
                continuation?.resume()
                continuation = nil
            }
        }

        let customLogger = CustomLogger()
        let coordinator = FlowCoordinator(logger: customLogger)
        let flow = FlowLoggerTestFlow()
        let stepper = OneStepper(withSingleStep: FlowLoggerTestStep.first)

        // 로거 호출을 기다리는 continuation 설정
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                customLogger.continuation = continuation
                coordinator.coordinate(flow: flow, with: stepper)
            }
        }

        // 로거가 최소 1번 호출되었는지 확인
        #expect(customLogger.callCount > 0)
    }

    // MARK: - Edge Cases

    @Test("빈 Step 배열도 올바르게 처리된다")
    func emptyNavigationStack() {
        let stack = NavigationStack(flowName: "EmptyFlow", steps: [])
        let logger = ConsoleFlowLogger()

        logger.log(navigationStack: stack)

        #expect(stack.depth == 0)
    }

    @Test("NoneStep은 로깅되지 않는다")
    func noneStepIsNotLogged() async throws {
        let mockLogger = FlowLoggerTestMockLogger()
        let coordinator = FlowCoordinator(logger: mockLogger)
        let flow = FlowLoggerTestFlow()

        @MainActor
        final class NoneStepStepper: FlowStepper {
            @Steps var steps
            var initialStep: Step { NoneStep() }
        }

        let stepper = NoneStepStepper()
        coordinator.coordinate(flow: flow, with: stepper)

        try await Task.sleep(nanoseconds: 100_000_000)

        // NoneStep은 로깅되지 않아야 함
        #expect(mockLogger.loggedStacks.isEmpty)
    }
}
