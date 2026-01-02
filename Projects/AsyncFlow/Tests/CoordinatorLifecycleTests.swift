//
//  CoordinatorLifecycleTests.swift
//  AsyncFlowTests
//
//  Created by jimmy on 2026. 1. 1.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("FlowCoordinator Lifecycle Tests")
struct CoordinatorLifecycleTests {
    // MARK: - Coordination Lifecycle

    @Test("Coordinator starts observing on coordinate")
    @MainActor
    func coordinatorStartsObserving() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()

        var observationStarted = false
        stepper.onObservationStart = { observationStarted = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { observationStarted }

        // Then
        #expect(observationStarted)
    }

    @Test("Coordinator processes initialStep")
    @MainActor
    func coordinatorProcessesInitialStep() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        // When
        await helper.start()
        await helper.waitForNavigation(count: 1)

        // Then
        #expect(helper.flow.navigateCallCount == 1)
        #expect((helper.flow.lastStep as? TestStep) == .initial)
    }

    @Test("Coordinator handles multiple steppers")
    @MainActor
    func coordinatorHandlesMultipleSteppers() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper1 = MockStepper()
        let stepper2 = MockStepper()

        stepper1.setInitialStep(TestStep.one)
        stepper2.setInitialStep(TestStep.two)

        var stepper1Ready = false
        var stepper2Ready = false
        stepper1.onObservationStart = { stepper1Ready = true }
        stepper2.onObservationStart = { stepper2Ready = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper1)
        await Test.waitUntil { stepper1Ready }

        coordinator.coordinate(flow: flow, with: stepper2)
        await Test.waitUntil { stepper2Ready }

        await Test.waitUntil { flow.navigateCallCount >= 2 }

        // Then
        #expect(flow.navigateCallCount >= 2)
    }

    // MARK: - Presentable Visibility Tests

    @Test("Steps ignored when presentable not visible")
    @MainActor
    func stepsIgnoredWhenNotVisible() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = SimpleTestFlow()
        let presentable = MockPresentable()
        let stepper = MockStepper()
        stepper.setInitialStep(NoneStep())

        presentable.setVisible(false)

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        flow.childPresentable = presentable
        flow.childStepper = stepper

        // When
        coordinator.coordinate(flow: flow, with: OneStepper(withSingleStep: SimpleStep.start))
        await Test.waitUntil { flow.navigateCallCount >= 1 }
        await Test.waitUntil { subscribed }

        let countBefore = flow.navigateCallCount
        stepper.emit(SimpleStep.next)
        await Test.wait(milliseconds: 100)

        // Then
        #expect(flow.navigateCallCount == countBefore)
    }

    @Test("Steps processed when presentable becomes visible")
    @MainActor
    func stepsProcessedWhenBecomesVisible() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = SimpleTestFlow()
        let presentable = MockPresentable()
        let stepper = MockStepper()
        stepper.setInitialStep(NoneStep())

        presentable.setVisible(false)

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        flow.childPresentable = presentable
        flow.childStepper = stepper

        // When
        coordinator.coordinate(flow: flow, with: OneStepper(withSingleStep: SimpleStep.start))
        await Test.waitUntil { flow.navigateCallCount >= 1 }
        await Test.waitUntil { subscribed }

        let countBefore = flow.navigateCallCount
        stepper.emit(SimpleStep.next)
        await Test.wait(milliseconds: 50)

        #expect(flow.navigateCallCount == countBefore)

        presentable.setVisible(true)
        await Test.waitUntil { flow.navigateCallCount > countBefore }

        // Then
        #expect(flow.navigateCallCount > countBefore)
    }

    @Test("AllowStepWhenNotPresented bypasses visibility check")
    @MainActor
    func allowStepWhenNotPresented() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = SimpleTestFlow()
        let presentable = MockPresentable()
        let stepper = MockStepper()

        presentable.setVisible(false)
        flow.allowNotPresented = true

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        flow.childPresentable = presentable
        flow.childStepper = stepper

        // When
        coordinator.coordinate(flow: flow, with: OneStepper(withSingleStep: SimpleStep.start))
        await Test.waitUntil { flow.navigateCallCount >= 1 }
        await Test.waitUntil { subscribed }

        stepper.emit(SimpleStep.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        // Then
        #expect(flow.navigateCallCount >= 2)
    }

    // MARK: - Dismiss Handling

    @Test("Coordinator stops observing when presentable dismissed")
    @MainActor
    func stopObservingWhenDismissed() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = SimpleTestFlow()
        let presentable = MockPresentable()
        let stepper = MockStepper()
        stepper.setInitialStep(NoneStep())

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        flow.childPresentable = presentable
        flow.childStepper = stepper

        // When
        coordinator.coordinate(flow: flow, with: OneStepper(withSingleStep: SimpleStep.start))
        await Test.waitUntil { flow.navigateCallCount >= 1 }
        await Test.waitUntil { subscribed }

        stepper.emit(SimpleStep.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        let countBeforeDismiss = flow.navigateCallCount
        presentable.dismiss()
        await Test.wait(milliseconds: 100)

        stepper.emit(SimpleStep.end)
        await Test.wait(milliseconds: 100)

        // Then
        #expect(flow.navigateCallCount == countBeforeDismiss)
    }

    @Test("AllowStepWhenDismissed allows steps after dismiss")
    @MainActor
    func allowStepWhenDismissed() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = SimpleTestFlow()
        let presentable = MockPresentable()
        let stepper = MockStepper()

        flow.allowDismissed = true

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        flow.childPresentable = presentable
        flow.childStepper = stepper

        // When
        coordinator.coordinate(flow: flow, with: OneStepper(withSingleStep: SimpleStep.start))
        await Test.waitUntil { flow.navigateCallCount >= 1 }
        await Test.waitUntil { subscribed }

        presentable.dismiss()
        await Test.wait(milliseconds: 50)

        stepper.emit(SimpleStep.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        // Then
        #expect(flow.navigateCallCount >= 2)
    }

    // MARK: - Navigation Events

    @Test("WillNavigate emits before navigation")
    @MainActor
    func willNavigateEmitsBeforeNavigation() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        var willNavigateCalled = false

        let willTask = Task {
            for await _ in helper.coordinator.willNavigate {
                willNavigateCalled = true
                break
            }
        }

        // When
        await helper.start()
        await Test.waitUntil { willNavigateCalled }

        willTask.cancel()

        // Then
        #expect(willNavigateCalled)
    }

    @Test("DidNavigate emits after navigation")
    @MainActor
    func didNavigateEmitsAfterNavigation() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        var didNavigateCalled = false
        var navigateCalled = false

        helper.flow.onNavigate = { _ in navigateCalled = true }

        let didTask = Task {
            for await _ in helper.coordinator.didNavigate {
                didNavigateCalled = true
                #expect(navigateCalled)
                break
            }
        }

        // When
        await helper.start()
        await Test.waitUntil { didNavigateCalled }

        didTask.cancel()

        // Then
        #expect(didNavigateCalled)
    }

    @Test("End contributor concept")
    @MainActor
    func endContributorConcept() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        // When
        await helper.start()
        await helper.waitForNavigation(count: 1)

        // Then
        #expect(helper.flow.navigateCallCount >= 1)
    }

    // MARK: - Memory Management

    @Test("Coordinator releases when flow dismissed")
    @MainActor
    func coordinatorReleasesWhenDismissed() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let presentable = MockPresentable()
        let stepper = MockStepper()

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        flow.nextContributors = .one(flowContributor: .contribute(
            withNextPresentable: presentable,
            withNextStepper: stepper
        ))

        // When
        coordinator.coordinate(flow: flow, with: OneStepper(withSingleStep: TestStep.initial))
        await Test.waitUntil { flow.navigateCallCount >= 1 }
        await Test.waitUntil { subscribed }

        presentable.dismiss()
        await Test.wait(milliseconds: 50)

        stepper.emit(TestStep.next)
        await Test.wait(milliseconds: 50)

        // Then
        #expect(flow.navigateCallCount == 1)
    }
}

// MARK: - Test Types

enum SimpleStep: Step, Equatable {
    case start
    case next
    case end
}

@MainActor
final class SimpleTestFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    var navigateCallCount = 0
    var childPresentable: MockPresentable?
    var childStepper: MockStepper?
    var allowNotPresented = false
    var allowDismissed = false

    func navigate(to step: Step) -> FlowContributors {
        navigateCallCount += 1

        if let simpleStep = step as? SimpleStep {
            switch simpleStep {
            case .start:
                if let presentable = childPresentable, let stepper = childStepper {
                    return .one(flowContributor: .contribute(
                        withNextPresentable: presentable,
                        withNextStepper: stepper,
                        allowStepWhenNotPresented: allowNotPresented,
                        allowStepWhenDismissed: allowDismissed
                    ))
                }
                return .none
            case .next, .end:
                return .none
            }
        }

        return .none
    }
}
