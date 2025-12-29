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
    @Test("Coordinator가 Step을 감지하고 navigate를 호출")
    @MainActor
    func coordination() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()
        stepper.setInitialStep(TestStep.initial)

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }
        await Test.waitUntil { flow.navigateCallCount >= 1 }

        stepper.emit(TestStep.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        // Then
        #expect(flow.navigateCallCount == 2)
        #expect((flow.lastStep as? TestStep) == .next)
    }

    @Test("Adapt 메서드가 Step 필터링")
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

    @Test("Navigation Event 스트림 동작")
    @MainActor
    func navigationEvents() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()
        stepper.setInitialStep(TestStep.initial)

        var subscribed = false
        var willReceived = false
        var didReceived = false

        stepper.onObservationStart = { subscribed = true }

        let willTask = Task {
            for await _ in coordinator.willNavigate {
                willReceived = true
                break
            }
        }

        let didTask = Task {
            for await _ in coordinator.didNavigate {
                didReceived = true
                break
            }
        }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }
        await Test.waitUntil { willReceived && didReceived }

        // Then
        willTask.cancel()
        didTask.cancel()

        #expect(willReceived)
        #expect(didReceived)
    }

    @Test("Multiple Contributors 처리")
    @MainActor
    func multipleContributors() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()
        stepper.setInitialStep(TestStep.initial)

        let nextStepper1 = MockStepper()
        let nextStepper2 = MockStepper()

        var subscribed = false
        var nextStepper1Subscribed = false
        var nextStepper2Subscribed = false

        stepper.onObservationStart = { subscribed = true }
        nextStepper1.onObservationStart = { nextStepper1Subscribed = true }
        nextStepper2.onObservationStart = { nextStepper2Subscribed = true }

        // When
        flow.nextContributors = .multiple(
            .contribute(withNextPresentable: MockPresentable(), withNextStepper: nextStepper1),
            .contribute(withNextPresentable: MockPresentable(), withNextStepper: nextStepper2)
        )

        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }
        await Test.waitUntil { nextStepper1Subscribed && nextStepper2Subscribed }

        flow.nextContributors = .none

        nextStepper1.emit(TestStep.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        nextStepper2.emit(TestStep.next)
        await Test.waitUntil { flow.navigateCallCount >= 3 }

        // Then
        #expect(flow.navigateCallCount == 3)
    }

    @Test("Child Flow 시작")
    @MainActor
    func childFlow() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()
        stepper.setInitialStep(TestStep.childFlow)

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }
        await Test.waitUntil { flow.childFlow != nil }

        guard let child = flow.childFlow else {
            #expect(Bool(false), "Child flow should be created")
            return
        }

        await Test.waitUntil { child.navigateCallCount > 0 }

        // Then
        #expect(child.navigateCallCount == 1)
        #expect((child.lastStep as? TestStep) == .initial)
    }

    @Test("외부에서 Step 주입 (DeepLink)")
    @MainActor
    func deepLinkNavigation() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper()

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
            coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        coordinator.navigate(to: TestStep.detail(id: 123))
        await Test.waitUntil { flow.navigateCallCount >= 1 }

        // Then
        #expect(flow.navigateCallCount == 1)
        #expect((flow.lastStep as? TestStep) == .detail(id: 123))
    }
}
