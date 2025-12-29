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
        let stepper1 = MockStepper<TestStep>()
        let stepper2 = MockStepper<TestStep>()

        var stepper1Ready = false
        var stepper2Ready = false

        stepper1.onObservationStart = { stepper1Ready = true }
        stepper2.onObservationStart = { stepper2Ready = true }

        let composite = CompositeStepper([stepper1, stepper2])

        let task = Task {
            var receivedSteps: [TestStep] = []
            for await step in composite.steps {
                receivedSteps.append(step)
                if receivedSteps.count == 2 { break }
            }
            return receivedSteps
        }

        // When
        await Test.waitUntil { stepper1Ready && stepper2Ready }

        stepper1.emit(.one)
        stepper2.emit(.two)

        let result = await task.value

        // Then
        #expect(result.count == 2)
        #expect(result.contains(.one))
        #expect(result.contains(.two))
    }
}
