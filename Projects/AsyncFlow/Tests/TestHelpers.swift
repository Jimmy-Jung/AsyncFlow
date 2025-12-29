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
        timeout: TimeInterval = 1.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                #expect(Bool(false), "Timeout waiting for condition")
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

// MARK: - Mock Flow

@MainActor
final class MockFlow: Flow {
    typealias StepType = TestStep

    let rootPresentable = MockPresentable()
    var root: any Presentable { rootPresentable }

    var navigateCallCount = 0
    var lastStep: TestStep?
    var nextContributors: FlowContributors<TestStep> = .none
    var childFlow: MockFlow?
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
        defer { onAdapt?(step) }
        if step == .end { return nil }
        return step
    }
}

// MARK: - Mock Presentable

final class MockPresentable: Presentable {
    #if canImport(UIKit)
        var viewController: PlatformViewController { PlatformViewController() }
    #elseif canImport(AppKit)
        var viewController: PlatformViewController { PlatformViewController() }
    #endif

    var isPresented: Bool = true
    var allowStepWhenDismissed: Bool = true

    private let dismissedStream = AsyncStream<Void>.makeStream()
    var onDismissed: AsyncStream<Void> { dismissedStream.stream }

    func dismiss() {
        isPresented = false
        dismissedStream.continuation.yield(())
        dismissedStream.continuation.finish()
    }
}

// MARK: - Test ViewModel

@MainActor
final class TestViewModel: Stepper {
    typealias StepType = TestStep
    @StepEmitter var stepEmitter: StepEmitter<TestStep>

    private var readyContinuation: AsyncStream<Void>.Continuation?
    private var isReady = false
    private var readyStream: AsyncStream<Void>!

    init() {
        readyStream = AsyncStream { [weak self] continuation in
            self?.readyContinuation = continuation
        }
    }

    var steps: AsyncStream<TestStep> {
        if !isReady {
            isReady = true
            readyContinuation?.yield(())
        }
        return stepEmitter.stream
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
