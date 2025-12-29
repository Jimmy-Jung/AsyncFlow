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
        let stepper = OneStepper(TestStep.initial)

        // When
        let task = Task {
            var steps: [TestStep] = []
            for await step in stepper.steps {
                steps.append(step)
                break
            }
            return steps
        }

        let receivedSteps = await task.value

        // Then
        #expect(receivedSteps == [.initial])
    }

    @Test("MockStepper 여러 Step 방출")
    @MainActor
    func mockStepper() async throws {
        // Given
        let stepper = MockStepper<TestStep>()

        let collectionTask = Task {
            var steps: [TestStep] = []
            for await step in stepper.steps {
                steps.append(step)
                if steps.count == 3 { break }
            }
            return steps
        }

        // When
        try await Task.sleep(nanoseconds: 10 * 1_000_000)

        stepper.emit(.initial)
        stepper.emit(.detail(id: 1))
        stepper.emit(.detail(id: 2))

        let receivedSteps = await collectionTask.value

        // Then
        #expect(receivedSteps == [.initial, .detail(id: 1), .detail(id: 2)])
    }
}
