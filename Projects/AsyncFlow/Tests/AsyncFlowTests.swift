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
    @Test("OneStepper should emit initial step")
    @MainActor
    func oneStepper() async throws {
        let stepper = OneStepper(TestStep.initial)

        let task = Task {
            var steps: [TestStep] = []
            for await step in stepper.steps {
                steps.append(step)
                break // OneStepper는 한 번만 방출하므로 수신 후 종료
            }
            return steps
        }

        let receivedSteps = await task.value

        #expect(receivedSteps == [.initial])
    }

    @Test("MockStepper should emit multiple steps")
    @MainActor
    func mockStepper() async throws {
        let stepper = MockStepper<TestStep>()

        let collectionTask = Task {
            var steps: [TestStep] = []
            for await step in stepper.steps {
                steps.append(step)
                if steps.count == 3 { break } // 3개 받고 종료
            }
            return steps
        }

        // 구독이 확실히 시작되도록 잠시 대기 (10ms)
        try await Task.sleep(nanoseconds: 10 * 1_000_000)

        stepper.emit(.initial)
        stepper.emit(.detail(id: 1))
        stepper.emit(.detail(id: 2))

        // 3개를 받을 때까지 대기 (타임아웃은 Task 내부 로직에 의존하거나 별도 처리 필요)
        let receivedSteps = await collectionTask.value

        #expect(receivedSteps == [.initial, .detail(id: 1), .detail(id: 2)])
    }
}

// MARK: - Test Fixtures

enum TestStep: Step, Equatable {
    case initial
    case detail(id: Int)
}
