//
//  FlowCoordinatorTests.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("FlowCoordinator Tests")
struct FlowCoordinatorTests {
    @Test("Coordinator detects steps and calls navigate")
    @MainActor
    func coordination() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        // When
        await helper.start()
        await helper.waitForNavigation(count: 1)
        await helper.emitAndWait(.next, expectedCount: 2)

        // Then
        #expect(helper.flow.navigateCallCount == 2)
        #expect((helper.flow.lastStep as? TestStep) == .next)
    }

    @Test("Adapt method filters steps")
    @MainActor
    func adaptFiltering() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()

        var subscribed = false
        var adaptCalled = false

        stepper.onObservationStart = { subscribed = true }
        flow.onAdapt = { _ in adaptCalled = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        stepper.emit(TestStep.end)
        await Test.waitUntil { adaptCalled }

        // Then
        #expect(adaptCalled)
        #expect(flow.navigateCallCount == 0)
    }

    @Test("Navigation events stream works correctly")
    @MainActor
    func navigationEvents() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        var willReceived = false
        var didReceived = false

        let willTask = Task {
            for await _ in helper.coordinator.willNavigate {
                willReceived = true
                break
            }
        }

        let didTask = Task {
            for await _ in helper.coordinator.didNavigate {
                didReceived = true
                break
            }
        }

        // When
        await helper.start()
        await Test.waitUntil { willReceived && didReceived }

        // Then
        willTask.cancel()
        didTask.cancel()

        #expect(willReceived)
        #expect(didReceived)
    }

    @Test("Multiple contributors are handled correctly")
    @MainActor
    func multipleContributors() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .initial)

        let nextStepper1 = MockStepper()
        let nextStepper2 = MockStepper()

        var nextStepper1Subscribed = false
        var nextStepper2Subscribed = false

        nextStepper1.onObservationStart = { nextStepper1Subscribed = true }
        nextStepper2.onObservationStart = { nextStepper2Subscribed = true }

        helper.flow.nextContributors = .multiple(
            .contribute(withNextPresentable: MockPresentable(), withNextStepper: nextStepper1),
            .contribute(withNextPresentable: MockPresentable(), withNextStepper: nextStepper2)
        )

        // When
        await helper.start()
        await Test.waitUntil { nextStepper1Subscribed && nextStepper2Subscribed }

        helper.flow.nextContributors = .none

        nextStepper1.emit(TestStep.next)
        await helper.waitForNavigation(count: 2)

        nextStepper2.emit(TestStep.next)
        await helper.waitForNavigation(count: 3)

        // Then
        #expect(helper.flow.navigateCallCount == 3)
    }

    @Test("Child flow starts correctly")
    @MainActor
    func childFlow() async {
        // Given
        let helper = CoordinationTestHelper(initialStep: .childFlow)

        // When
        await helper.start()
        await Test.waitUntil { helper.flow.childFlow != nil }

        guard let child = helper.flow.childFlow else {
            #expect(Bool(false), "Child flow should be created")
            return
        }

        await Test.waitUntil { child.navigateCallCount > 0 }

        // Then
        #expect(child.navigateCallCount == 1)
        #expect((child.lastStep as? TestStep) == .initial)
    }

    @Test("External step injection works (DeepLink)")
    @MainActor
    func deepLinkNavigation() async {
        // Given
        let helper = CoordinationTestHelper()

        // When
        await helper.start()
        helper.coordinator.navigate(to: TestStep.detail(id: 123))
        await helper.waitForNavigation(count: 1)

        // Then
        #expect(helper.flow.navigateCallCount == 1)
        #expect((helper.flow.lastStep as? TestStep) == .detail(id: 123))
    }
}
