//
//  StepperTests.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("Stepper Tests")
struct StepperTests {
    @Test("Stepper Step 방출")
    @MainActor
    func stepperEmit() async throws {
        // Given
        let viewModel = TestViewModel()

        let task = Task {
            var receivedSteps: [TestStep] = []
            for await step in viewModel.steps.stream {
                if let testStep = step as? TestStep {
                    receivedSteps.append(testStep)
                }
                if receivedSteps.count == 2 { break }
            }
            return receivedSteps
        }

        // When
        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.one)
        viewModel.emit(.two)

        let receivedSteps = await task.value

        // Then
        #expect(receivedSteps.count == 2)
        #expect(receivedSteps[0] == .one)
        #expect(receivedSteps[1] == .two)
    }

    @Test("Stepper가 여러 Step을 순서대로 방출하는지 확인")
    @MainActor
    func stepperMultipleEmits() async throws {
        let viewModel = TestViewModel()
        let stream = viewModel.steps.stream

        let task = Task {
            var receivedSteps: [TestStep] = []
            for await step in stream {
                if let testStep = step as? TestStep {
                    receivedSteps.append(testStep)
                }
                if receivedSteps.count == 3 { break }
            }
            return receivedSteps
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.one)
        viewModel.emit(.two)
        viewModel.emit(.three)

        let receivedSteps = await task.value

        #expect(receivedSteps == [.one, .two, .three])
    }

    // MARK: - Multicast Tests

    @Test("Stepper가 다중 구독(Multicast)을 지원하는지 확인")
    @MainActor
    func stepperMulticast() async throws {
        let viewModel = TestViewModel()
        let stream1 = viewModel.steps.stream
        let stream2 = viewModel.steps.stream

        try await confirmation("Both streams received event", expectedCount: 2) { confirm in
            let task1 = Task {
                for await _ in stream1 {
                    confirm()
                    break
                }
            }

            let task2 = Task {
                for await _ in stream2 {
                    confirm()
                    break
                }
            }

            try await Task.sleep(nanoseconds: 10_000_000)

            viewModel.emit(.one)

            _ = await (task1.result, task2.result)
        }
    }

    @Test("여러 구독자가 모든 Step을 동일하게 받는지 확인")
    @MainActor
    func multicastAllSteps() async throws {
        let viewModel = TestViewModel()
        let stream1 = viewModel.steps.stream
        let stream2 = viewModel.steps.stream
        let stream3 = viewModel.steps.stream

        let task1 = Task {
            var steps: [TestStep] = []
            for await step in stream1 {
                if let testStep = step as? TestStep {
                    steps.append(testStep)
                }
                if steps.count == 2 { break }
            }
            return steps
        }

        let task2 = Task {
            var steps: [TestStep] = []
            for await step in stream2 {
                if let testStep = step as? TestStep {
                    steps.append(testStep)
                }
                if steps.count == 2 { break }
            }
            return steps
        }

        let task3 = Task {
            var steps: [TestStep] = []
            for await step in stream3 {
                if let testStep = step as? TestStep {
                    steps.append(testStep)
                }
                if steps.count == 2 { break }
            }
            return steps
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.one)
        viewModel.emit(.two)

        let (steps1, steps2, steps3) = await (task1.value, task2.value, task3.value)

        #expect(steps1 == [.one, .two])
        #expect(steps2 == [.one, .two])
        #expect(steps3 == [.one, .two])
    }

    // MARK: - Cancellation Tests

    @Test("구독 취소 후 Step을 받지 않는지 확인")
    @MainActor
    func subscriptionCancellation() async throws {
        let viewModel = TestViewModel()
        let stream = viewModel.steps.stream

        var receivedSteps: [TestStep] = []

        let task = Task {
            for await step in stream {
                if let testStep = step as? TestStep {
                    receivedSteps.append(testStep)
                }
            }
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.one)
        try await Task.sleep(nanoseconds: 10_000_000)

        task.cancel()
        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.two)
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(receivedSteps.count == 1)
        #expect(receivedSteps[0] == .one)
    }

    @Test("일부 구독자가 취소되어도 다른 구독자는 계속 받음")
    @MainActor
    func partialCancellation() async throws {
        let viewModel = TestViewModel()
        let stream1 = viewModel.steps.stream
        let stream2 = viewModel.steps.stream

        var steps1: [TestStep] = []
        var steps2: [TestStep] = []

        let task1 = Task {
            for await step in stream1 {
                if let testStep = step as? TestStep {
                    steps1.append(testStep)
                }
            }
        }

        let task2 = Task {
            for await step in stream2 {
                if let testStep = step as? TestStep {
                    steps2.append(testStep)
                }
                if steps2.count == 2 { break }
            }
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.one)
        try await Task.sleep(nanoseconds: 10_000_000)

        task1.cancel()
        try await Task.sleep(nanoseconds: 10_000_000)

        viewModel.emit(.two)

        _ = await task2.value

        #expect(steps1.count == 1)
        #expect(steps1[0] == .one)
        #expect(steps2.count == 2)
        #expect(steps2 == [.one, .two])
    }

    // MARK: - OneStepper Tests

    @Test("OneStepper가 초기값만 방출하는지 확인")
    @MainActor
    func oneStepper() async {
        let stepper = OneStepper(withSingleStep: TestStep.one)

        #expect(stepper.initialStep is TestStep)
        #expect((stepper.initialStep as? TestStep) == .one)
    }

    // MARK: - Concurrent Emit Tests

    @Test("빠른 연속 방출이 모두 전달되는지 확인")
    @MainActor
    func rapidEmits() async throws {
        let viewModel = TestViewModel()
        let stream = viewModel.steps.stream

        let task = Task {
            var steps: [TestStep] = []
            for await step in stream {
                if let testStep = step as? TestStep {
                    steps.append(testStep)
                }
                if steps.count == 100 { break }
            }
            return steps
        }

        try await Task.sleep(nanoseconds: 10_000_000)

        for i in 0 ..< 100 {
            viewModel.emit(i % 2 == 0 ? .one : .two)
        }

        let steps = await task.value
        #expect(steps.count == 100)
    }
}
