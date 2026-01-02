//
//  FlowAdaptTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("Flow Adapt Tests")
struct FlowAdaptTests {
    // MARK: - Basic Adapt Tests

    @Test("Adapt returns original step by default")
    @MainActor
    func adaptReturnsOriginalStep() async {
        // Given
        let flow = SimpleFlow()
        let step = TestStep.initial

        // When
        let adaptedStep = await flow.adapt(step: step)

        // Then
        #expect((adaptedStep as? TestStep) == step)
    }

    @Test("Adapt filters out specific steps")
    @MainActor
    func adaptFiltersSteps() async {
        // Given
        let flow = FilteringFlow()

        // When
        let allowedStep = await flow.adapt(step: TestStep.initial)
        let filteredStep = await flow.adapt(step: TestStep.end)

        // Then
        #expect((allowedStep as? TestStep) == .initial)
        #expect(filteredStep is NoneStep)
    }

    @Test("Adapt transforms steps")
    @MainActor
    func adaptTransformsSteps() async {
        // Given
        let flow = TransformingFlow()

        // When
        let transformedStep = await flow.adapt(step: TestStep.detail(id: 1))

        // Then
        #expect((transformedStep as? TestStep) == .detail(id: 100))
    }

    // MARK: - Authorization Tests

    @Test("Adapt blocks unauthorized steps")
    @MainActor
    func adaptBlocksUnauthorizedSteps() async {
        // Given
        let flow = AuthorizingFlow(isAuthorized: false)

        // When
        let blockedStep = await flow.adapt(step: TestStep.detail(id: 1))

        // Then
        #expect(blockedStep is NoneStep)
    }

    @Test("Adapt allows authorized steps")
    @MainActor
    func adaptAllowsAuthorizedSteps() async {
        // Given
        let flow = AuthorizingFlow(isAuthorized: true)

        // When
        let allowedStep = await flow.adapt(step: TestStep.detail(id: 1))

        // Then
        #expect((allowedStep as? TestStep) == .detail(id: 1))
    }

    // MARK: - Async Adapt Tests

    @Test("Adapt with async validation")
    @MainActor
    func adaptWithAsyncValidation() async {
        // Given
        let flow = AsyncValidatingFlow()

        // When
        let validatedStep = await flow.adapt(step: TestStep.initial)

        // Then
        #expect((validatedStep as? TestStep) == .initial)
    }

    @Test("Adapt with async failure")
    @MainActor
    func adaptWithAsyncFailure() async {
        // Given
        let flow = AsyncValidatingFlow()

        // When
        let failedStep = await flow.adapt(step: TestStep.end)

        // Then
        #expect(failedStep is NoneStep)
    }

    // MARK: - Coordinator Integration Tests

    @Test("Coordinator respects adapt filtering")
    @MainActor
    func coordinatorRespectsAdapt() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = FilteringFlow()
        let stepper = MockStepper()

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        stepper.emit(TestStep.initial)
        await Test.waitUntil { flow.navigateCallCount >= 1 }

        stepper.emit(TestStep.end) // Should be filtered
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(flow.navigateCallCount == 1)
        #expect((flow.lastStep as? TestStep) == .initial)
    }

    @Test("Adapt can redirect steps")
    @MainActor
    func adaptCanRedirectSteps() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = RedirectingFlow()
        let stepper = MockStepper()

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        stepper.emit(TestStep.detail(id: 1))
        await Test.waitUntil { flow.navigateCallCount >= 1 }

        // Then
        #expect(flow.navigateCallCount == 1)
        #expect((flow.lastStep as? TestStep) == .initial)
    }

    // MARK: - Complex Scenarios

    @Test("Adapt with state-dependent logic")
    @MainActor
    func adaptWithStateDependentLogic() async {
        // Given
        let flow = StatefulFlow()

        // When
        let firstAttempt = await flow.adapt(step: TestStep.detail(id: 1))
        flow.allowDetail = true
        let secondAttempt = await flow.adapt(step: TestStep.detail(id: 1))

        // Then
        #expect(firstAttempt is NoneStep)
        #expect((secondAttempt as? TestStep) == .detail(id: 1))
    }

    @Test("Adapt with multiple conditions")
    @MainActor
    func adaptWithMultipleConditions() async {
        // Given
        let flow = MultiConditionFlow()

        // When
        let step1 = await flow.adapt(step: TestStep.initial)
        let step2 = await flow.adapt(step: TestStep.detail(id: 0))
        let step3 = await flow.adapt(step: TestStep.detail(id: 100))
        let step4 = await flow.adapt(step: TestStep.end)

        // Then
        #expect((step1 as? TestStep) == .initial)
        #expect(step2 is NoneStep) // id가 0이면 필터링
        #expect((step3 as? TestStep) == .detail(id: 100))
        #expect(step4 is NoneStep) // end는 필터링
    }
}

// MARK: - Test Flows

@MainActor
final class SimpleFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    var navigateCallCount = 0
    var lastStep: Step?

    func navigate(to step: Step) -> FlowContributors {
        navigateCallCount += 1
        lastStep = step
        return .none
    }
}

@MainActor
final class FilteringFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    var navigateCallCount = 0
    var lastStep: Step?

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        // end는 필터링
        if testStep == .end {
            return NoneStep()
        }

        return step
    }

    func navigate(to step: Step) -> FlowContributors {
        navigateCallCount += 1
        lastStep = step
        return .none
    }
}

@MainActor
final class TransformingFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        // detail id를 100으로 변환
        if case .detail = testStep {
            return TestStep.detail(id: 100)
        }

        return step
    }

    func navigate(to _: Step) -> FlowContributors {
        .none
    }
}

@MainActor
final class AuthorizingFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    let isAuthorized: Bool

    init(isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        // detail은 권한 필요
        if case .detail = testStep {
            return isAuthorized ? step : NoneStep()
        }

        return step
    }

    func navigate(to _: Step) -> FlowContributors {
        .none
    }
}

@MainActor
final class AsyncValidatingFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        // 비동기 검증 시뮬레이션
        try? await Task.sleep(nanoseconds: 10_000_000)

        // end는 검증 실패
        if testStep == .end {
            return NoneStep()
        }

        return step
    }

    func navigate(to _: Step) -> FlowContributors {
        .none
    }
}

@MainActor
final class RedirectingFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    var navigateCallCount = 0
    var lastStep: Step?

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        // detail은 initial로 리다이렉트
        if case .detail = testStep {
            return TestStep.initial
        }

        return step
    }

    func navigate(to step: Step) -> FlowContributors {
        navigateCallCount += 1
        lastStep = step
        return .none
    }
}

@MainActor
final class StatefulFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    var allowDetail = false

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        // detail은 allowDetail이 true일 때만 허용
        if case .detail = testStep {
            return allowDetail ? step : NoneStep()
        }

        return step
    }

    func navigate(to _: Step) -> FlowContributors {
        .none
    }
}

@MainActor
final class MultiConditionFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    func adapt(step: Step) async -> Step {
        guard let testStep = step as? TestStep else { return step }

        switch testStep {
        case .end:
            return NoneStep()
        case let .detail(id):
            // id가 0이면 필터링
            return id > 0 ? step : NoneStep()
        default:
            return step
        }
    }

    func navigate(to _: Step) -> FlowContributors {
        .none
    }
}
