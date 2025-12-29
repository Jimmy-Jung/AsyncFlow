//
//  AsyncFlowTests.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("AsyncFlow Core Tests")
struct AsyncFlowTests {
    @Test("OneStepper 초기 Step 방출")
    @MainActor
    func oneStepper() async {
        // Given
        let stepper = OneStepper(withSingleStep: TestStep.initial)

        // Then
        let initialStep = stepper.initialStep
        #expect(initialStep is TestStep)
        #expect((initialStep as? TestStep) == .initial)
    }

    @Test("DefaultStepper는 NoneStep 반환")
    @MainActor
    func defaultStepper() async {
        // Given
        let stepper = DefaultStepper()

        // Then
        #expect(stepper.initialStep is NoneStep)
    }

    @Test("NoneStep이 Equatable을 준수")
    func noneStepEquatable() {
        // Given
        let step1 = NoneStep()
        let step2 = NoneStep()

        // Then
        #expect(step1 == step2)
    }

    @Test("MockStepper 여러 Step 방출")
    @MainActor
    func mockStepper() async throws {
        // Given
        let stepper = MockStepper()

        let collectionTask = Task {
            var steps: [Step] = []
            for await step in stepper.steps.stream {
                steps.append(step)
                if steps.count == 3 { break }
            }
            return steps
        }

        // When
        try await Task.sleep(nanoseconds: 10 * 1_000_000)

        stepper.emit(TestStep.initial)
        stepper.emit(TestStep.detail(id: 1))
        stepper.emit(TestStep.detail(id: 2))

        let receivedSteps = await collectionTask.value

        // Then
        #expect(receivedSteps.count == 3)
        #expect((receivedSteps[0] as? TestStep) == .initial)
        #expect((receivedSteps[1] as? TestStep) == .detail(id: 1))
        #expect((receivedSteps[2] as? TestStep) == .detail(id: 2))
    }
}
