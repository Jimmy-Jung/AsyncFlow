//
//  TestHelpers.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

// MARK: - Test Error

enum TestError: Error {
    case timeout(String)
}

// MARK: - Common Test Step

enum TestStep: Step, Equatable, Sendable {
    case initial
    case detail(id: Int)
    case next
    case end
    case childFlow
    case one
    case two
    case three
}

// MARK: - Test Helpers

extension Test {
    @MainActor
    static func waitUntil(
        timeout: TimeInterval = 3.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() <= deadline else {
                #expect(Bool(false), "Timeout waiting for condition")
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    @MainActor
    static func wait(milliseconds: Int) async {
        try? await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
    }
}

// MARK: - Coordination Test Helper

@MainActor
struct CoordinationTestHelper {
    let coordinator: FlowCoordinator
    let flow: MockFlow
    let stepper: MockStepper

    init(initialStep: TestStep? = nil) {
        coordinator = FlowCoordinator()
        flow = MockFlow()
        stepper = MockStepper()

        if let initialStep = initialStep {
            stepper.setInitialStep(initialStep)
        }
    }

    func start() async {
        var subscribed = false
        stepper.onObservationStart = { subscribed = true }

        coordinator.coordinate(flow: flow, with: stepper)

        await Test.waitUntil { subscribed }
    }

    func waitForNavigation(count: Int) async {
        await Test.waitUntil { flow.navigateCallCount >= count }
    }

    func emitAndWait(_ step: TestStep, expectedCount: Int) async {
        stepper.emit(step)
        await waitForNavigation(count: expectedCount)
    }
}

// MARK: - Mock Flow

@MainActor
final class MockFlow: Flow {
    let rootPresentable = MockPresentable()
    var root: Presentable { rootPresentable }

    var navigateCallCount = 0
    var lastStep: Step?
    var nextContributors: FlowContributors = .none
    var childFlow: MockFlow?
    var onNavigate: ((Step) -> Void)?
    var onAdapt: ((Step) -> Void)?

    func navigate(to step: Step) -> FlowContributors {
        navigateCallCount += 1
        lastStep = step
        onNavigate?(step)

        if let testStep = step as? TestStep, testStep == .childFlow {
            let child = MockFlow()
            childFlow = child
            let stepper = OneStepper(withSingleStep: TestStep.initial)
            return .one(flowContributor: .contribute(
                withNextPresentable: child,
                withNextStepper: stepper
            ))
        }

        return nextContributors
    }

    func adapt(step: Step) async -> Step {
        defer {
            if let testStep = step as? TestStep {
                onAdapt?(testStep)
            }
        }
        if let testStep = step as? TestStep, testStep == .end {
            return NoneStep()
        }
        return step
    }
}

// MARK: - Mock Presentable

@MainActor
final class MockPresentable: Presentable {
    private let visibilitySubject = AsyncReplaySubject<Bool>(bufferSize: 1)
    private let dismissSubject = AsyncPassthroughSubject<Void>()

    var isVisibleStream: AsyncStream<Bool> { visibilitySubject.stream }
    var onDismissed: AsyncStream<Void> { dismissSubject.stream }

    var isPresented: Bool = true
    private var currentVisibility: Bool = true

    func setVisible(_ visible: Bool) {
        currentVisibility = visible
        visibilitySubject.send(visible)
    }

    func dismiss() {
        isPresented = false
        dismissSubject.send(())
    }
}

// MARK: - Test ViewModel

@MainActor
final class TestViewModel: FlowStepper {
    let steps = AsyncReplaySubject<Step>(bufferSize: 1)

    private var readyContinuation: AsyncStream<Void>.Continuation?
    private var isReady = false
    private var readyStream: AsyncStream<Void>!

    init() {
        readyStream = AsyncStream { [weak self] continuation in
            self?.readyContinuation = continuation
        }
    }

    func readyToEmitSteps() {
        if !isReady {
            isReady = true
            readyContinuation?.yield(())
        }
    }

    func emit(_ step: TestStep) {
        steps.send(step)
    }

    func waitUntilReady(timeout: TimeInterval = 1.0) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var ready = false

        let readyTask = Task {
            for await _ in readyStream {
                ready = true
                break
            }
        }

        while !ready, Date() < deadline {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }

        readyTask.cancel()

        guard ready else {
            throw TestError.timeout("Timeout waiting for TestViewModel to be ready")
        }
    }
}
