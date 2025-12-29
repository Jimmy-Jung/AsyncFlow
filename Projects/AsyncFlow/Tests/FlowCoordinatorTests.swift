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
    // MARK: - Test Helpers

    enum TestStep: Step, Equatable {
        case initial
        case next
        case end
        case childFlow
    }

    @MainActor
    final class MockFlow: Flow {
        typealias StepType = TestStep

        // 중요: 매번 새로운 인스턴스를 만들지 않고 유지해야 함
        let rootPresentable = MockPresentable()
        var root: any Presentable { return rootPresentable }

        // 호출 추적
        var navigateCallCount = 0
        var lastStep: TestStep?

        // 반환할 Contributor 설정
        var nextContributors: FlowContributors<TestStep> = .none

        // 자식 Flow 추적
        var childFlow: MockFlow?

        // 테스트 훅 (Events)
        var onNavigate: ((TestStep) -> Void)?
        var onAdapt: ((TestStep) -> Void)?

        func navigate(to step: TestStep) async -> FlowContributors<TestStep> {
            navigateCallCount += 1
            lastStep = step
            onNavigate?(step)

            if step == .childFlow {
                let child = MockFlow()
                childFlow = child
                let stepper = OneStepper(TestStep.initial)
                return .one(.contribute(presentable: child, stepper: stepper))
            }

            return nextContributors
        }

        func adapt(step: TestStep) async -> TestStep? {
            // adapt가 완료되었음을 알림
            defer { onAdapt?(step) }

            if step == .end { return nil }
            return step
        }
    }

    final class MockPresentable: Presentable {
        #if canImport(UIKit)
            var viewController: PlatformViewController { PlatformViewController() }
        #elseif canImport(AppKit)
            var viewController: PlatformViewController { PlatformViewController() }
        #endif

        var isPresented: Bool = true

        // 제어 가능한 스트림
        private let dismissedStream = AsyncStream<Void>.makeStream()
        var onDismissed: AsyncStream<Void> { dismissedStream.stream }
        var allowStepWhenDismissed: Bool = true

        func dismiss() {
            isPresented = false
            dismissedStream.continuation.yield(())
            dismissedStream.continuation.finish()
        }
    }

    // MARK: - Tests

    @Test("Coordinator가 Step을 감지하고 navigate를 호출하는지 확인")
    @MainActor
    func coordination() async {
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper<TestStep>()

        // 구독 대기
        var subscribed = false
        stepper.onObservationStart = { subscribed = true }
        coordinator.coordinate(flow: flow, with: stepper)

        // 구독 확인 대기
        var retries = 0
        while !subscribed, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }
        #expect(subscribed, "Stepper should be subscribed")

        // 이벤트 방출
        stepper.emit(.initial)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 대기

        stepper.emit(.next)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 대기

        #expect(flow.navigateCallCount == 2)
        #expect(flow.lastStep == .next)
    }

    @Test("Adapt 메서드가 Step을 필터링하는지 확인")
    @MainActor
    func adaptFiltering() async {
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper<TestStep>()

        // 구독 대기
        var subscribed = false
        stepper.onObservationStart = { subscribed = true }
        coordinator.coordinate(flow: flow, with: stepper)

        // 구독 확인 대기
        var retries = 0
        while !subscribed, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }
        #expect(subscribed, "Stepper should be subscribed")

        // Adapt가 호출되었는지 확인
        var adaptCalled = false
        flow.onAdapt = { _ in adaptCalled = true }

        stepper.emit(.end)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 대기

        #expect(adaptCalled, "Adapt should be called")
        #expect(flow.navigateCallCount == 0, "Navigate should not be called when step is filtered")
    }

    @Test("Navigation Event 스트림 동작 확인")
    @MainActor
    func navigationEvents() async {
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper<TestStep>()

        let willStream = coordinator.willNavigate
        let didStream = coordinator.didNavigate

        // 구독 대기
        var subscribed = false
        stepper.onObservationStart = { subscribed = true }
        coordinator.coordinate(flow: flow, with: stepper)

        // 구독 확인 대기
        var retries = 0
        while !subscribed, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }
        #expect(subscribed, "Stepper should be subscribed")

        // 이벤트 수신 Task 설정
        var willReceived = false
        var didReceived = false

        let willTask = Task {
            for await _ in willStream {
                willReceived = true
                break
            }
        }

        let didTask = Task {
            for await _ in didStream {
                didReceived = true
                break
            }
        }

        // Step 방출
        stepper.emit(.initial)

        // 이벤트 수신 대기
        retries = 0
        while !willReceived || !didReceived, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }

        willTask.cancel()
        didTask.cancel()

        #expect(willReceived, "willNavigate event should be received")
        #expect(didReceived, "didNavigate event should be received")
    }

    @Test("Multiple Contributors 처리 확인")
    @MainActor
    func multipleContributors() async {
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper<TestStep>()
        let nextStepper1 = MockStepper<TestStep>()
        let nextStepper2 = MockStepper<TestStep>()

        flow.nextContributors = .multiple(
            .contribute(presentable: MockPresentable(), stepper: nextStepper1),
            .contribute(presentable: MockPresentable(), stepper: nextStepper2)
        )

        // 메인 Stepper 구독
        var subscribed = false
        stepper.onObservationStart = { subscribed = true }
        coordinator.coordinate(flow: flow, with: stepper)

        // 구독 확인 대기
        var retries = 0
        while !subscribed, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }
        #expect(subscribed, "Main stepper should be subscribed")

        // 다음 Stepper 구독 추적
        var nextStepper1Subscribed = false
        var nextStepper2Subscribed = false
        nextStepper1.onObservationStart = { nextStepper1Subscribed = true }
        nextStepper2.onObservationStart = { nextStepper2Subscribed = true }

        // 초기 Step 방출
        stepper.emit(.initial)

        // 다음 Stepper 구독 대기
        retries = 0
        while !nextStepper1Subscribed || !nextStepper2Subscribed, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }
        #expect(nextStepper1Subscribed, "Next stepper 1 should be subscribed")
        #expect(nextStepper2Subscribed, "Next stepper 2 should be subscribed")

        // 자식 Stepper 이벤트 방출
        nextStepper1.emit(.next)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        nextStepper2.emit(.next)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        #expect(flow.navigateCallCount == 3, "Navigate should be called 3 times (1 initial + 2 from child steppers)")
    }

    @Test("Child Flow 시작 확인")
    @MainActor
    func testChildFlow() async {
        let coordinator = FlowCoordinator()
        let flow = MockFlow()
        let stepper = MockStepper<TestStep>()

        // 구독 대기
        var subscribed = false
        stepper.onObservationStart = { subscribed = true }
        coordinator.coordinate(flow: flow, with: stepper)

        // 구독 확인 대기
        var retries = 0
        while !subscribed, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }
        #expect(subscribed, "Stepper should be subscribed")

        // Child Flow 생성
        stepper.emit(.childFlow)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        #expect(flow.childFlow != nil, "Child flow should be created")
        guard let childFlow = flow.childFlow else { return }

        // Child Flow의 OneStepper는 즉시 방출되지만, 비동기 큐에 있을 수 있음
        retries = 0
        while childFlow.navigateCallCount == 0, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }

        #expect(childFlow.navigateCallCount == 1, "Child flow should navigate once")
        #expect(childFlow.lastStep == .initial, "Child flow should receive initial step")
    }

    @Test("Presentable이 닫히면 리소스가 해제되는지 확인")
    @MainActor
    func resourceDeallocationOnDismiss() async {
        let coordinator = FlowCoordinator()
        weak var weakFlow: MockFlow?
        weak var weakStepper: MockStepper<TestStep>?

        autoreleasepool {
            let flow = MockFlow()
            let stepper = MockStepper<TestStep>()
            weakFlow = flow
            weakStepper = stepper

            coordinator.coordinate(flow: flow, with: stepper)
            flow.rootPresentable.dismiss()
        }

        // 리소스 해제 대기
        var retries = 0
        while weakFlow != nil || weakStepper != nil, retries < 100 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            retries += 1
        }

        #expect(weakFlow == nil, "Flow should be deallocated")
        #expect(weakStepper == nil, "Stepper should be deallocated")
    }
}
