//
//  CompositeStepperTests.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("CompositeStepper Tests")
struct CompositeStepperTests {
    @Test("CompositeStepper 여러 Stepper 이벤트 병합")
    @MainActor
    func compositeStream() async {
        // Given
        let stepper1 = MockStepper()
        let stepper2 = MockStepper()

        var stepper1Ready = false
        var stepper2Ready = false

        stepper1.onObservationStart = { stepper1Ready = true }
        stepper2.onObservationStart = { stepper2Ready = true }

        let composite = CompositeStepper(steppers: [stepper1, stepper2])

        let task = Task {
            var receivedSteps: [TestStep] = []
            for await step in composite.steps.stream {
                if let testStep = step as? TestStep {
                    receivedSteps.append(testStep)
                }
                if receivedSteps.count == 2 { break }
            }
            return receivedSteps
        }

        // When
        composite.readyToEmitSteps()
        await Test.waitUntil { stepper1Ready && stepper2Ready }

        stepper1.emit(TestStep.one)
        stepper2.emit(TestStep.two)

        let result = await task.value

        // Then
        #expect(result.count == 2)
        #expect(result.contains(.one))
        #expect(result.contains(.two))
    }

    @Test("CompositeStepper 초기 Step 병합")
    @MainActor
    func compositeInitialSteps() async {
        // Given
        let stepper1 = MockStepper()
        let stepper2 = MockStepper()

        stepper1.setInitialStep(TestStep.one)
        stepper2.setInitialStep(TestStep.two)

        let composite = CompositeStepper(steppers: [stepper1, stepper2])

        // When
        composite.readyToEmitSteps()

        // Then - initialStep 병합은 없지만 readyToEmitSteps에서 각 stepper의 initialStep을 방출
        #expect(composite.initialStep is NoneStep)
    }
}
