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
    enum TestStep: Step, Equatable, Sendable {
        case one
        case two
    }

    @Test("CompositeStepper가 여러 Stepper의 이벤트를 병합하는지 확인")
    @MainActor
    func compositeStream() async throws {
        let stepper1 = MockStepper<TestStep>()
        let stepper2 = MockStepper<TestStep>()
        let composite = CompositeStepper([stepper1, stepper2])

        let stream = composite.steps

        let task = Task {
            var receivedSteps: [TestStep] = []
            for await step in stream {
                receivedSteps.append(step)
                if receivedSteps.count == 2 { break }
            }
            return receivedSteps
        }

        stepper1.emit(.one)
        stepper2.emit(.two)

        let result = await task.value

        #expect(result.count == 2)
        #expect(result.contains(.one))
        #expect(result.contains(.two))
    }
}
