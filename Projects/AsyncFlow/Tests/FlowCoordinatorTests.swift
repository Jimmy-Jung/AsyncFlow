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
        let stepper = MockStepper<TestStep>()

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        stepper.emit(.initial)
        await Test.waitUntil { flow.navigateCallCount >= 1 }

        stepper.emit(.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        // Then
        #expect(flow.navigateCallCount == 2)
        #expect(flow.lastStep == .next)
    }

    @Test("Adapt 메서드가 Step 필터링")
    @MainActor
    func adaptFiltering() async {
        // Given
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper<TestStep>()

        var subscribed = false
        var adaptCalled = false

        stepper.onObservationStart = { subscribed = true }
        flow.onAdapt = { _ in adaptCalled = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        stepper.emit(.end)
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
        let stepper = MockStepper<TestStep>()

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

        stepper.emit(.initial)
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
        let stepper = MockStepper<TestStep>()
        let nextStepper1 = MockStepper<TestStep>()
        let nextStepper2 = MockStepper<TestStep>()

        var subscribed = false
        var nextStepper1Subscribed = false
        var nextStepper2Subscribed = false

        stepper.onObservationStart = { subscribed = true }
        nextStepper1.onObservationStart = { nextStepper1Subscribed = true }
        nextStepper2.onObservationStart = { nextStepper2Subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        flow.nextContributors = .multiple(
            .contribute(presentable: MockPresentable(), stepper: nextStepper1),
            .contribute(presentable: MockPresentable(), stepper: nextStepper2)
        )

        stepper.emit(.initial)
        await Test.waitUntil { nextStepper1Subscribed && nextStepper2Subscribed }

        flow.nextContributors = .none

        nextStepper1.emit(.next)
        await Test.waitUntil { flow.navigateCallCount >= 2 }

        nextStepper2.emit(.next)
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
        let stepper = MockStepper<TestStep>()

        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        // When
        coordinator.coordinate(flow: flow, with: stepper)
        await Test.waitUntil { subscribed }

        stepper.emit(.childFlow)
        await Test.waitUntil { flow.childFlow != nil }

        guard let child = flow.childFlow else {
            #expect(Bool(false), "Child flow should be created")
            return
        }

        await Test.waitUntil { child.navigateCallCount > 0 }

        // Then
        #expect(child.navigateCallCount == 1)
        #expect(child.lastStep == .initial)
    }

    @Test("Presentable 닫힘 시 리소스 해제")
    @MainActor
    func resourceDeallocation() async {
        // Given
        let coordinator = FlowCoordinator()
        weak var weakFlow: MockFlow?
        weak var weakStepper: MockStepper<TestStep>?

        // When
        autoreleasepool {
            let flow = MockFlow()
            let stepper = MockStepper<TestStep>()
            weakFlow = flow
            weakStepper = stepper

            coordinator.coordinate(flow: flow, with: stepper)
            flow.rootPresentable.dismiss()
        }

        await Test.waitUntil { weakFlow == nil && weakStepper == nil }

        // Then
        #expect(weakFlow == nil)
        #expect(weakStepper == nil)
    }
}
