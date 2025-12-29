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
    // MARK: - Test Helpers

    enum TestStep: Step {
        case one
        case two
    }

    @MainActor
    final class TestViewModel: StepEmittable {
        typealias StepType = TestStep
    }

    // MARK: - Tests

    @Test("StepEmittable이 Step을 정상적으로 방출하는지 확인")
    @MainActor
    func stepEmittable() async {
        let viewModel = TestViewModel()
        let stream = viewModel.steps // 스트림 미리 캡처 (Continuation 등록)

        let task = Task {
            var receivedSteps: [TestStep] = []
            for await step in stream {
                receivedSteps.append(step)
                if receivedSteps.count == 2 { break }
            }
            return receivedSteps
        }

        viewModel.emit(.one)
        viewModel.emit(.two)

        let receivedSteps = await task.value

        #expect(receivedSteps.count == 2)
        #expect(receivedSteps[0] == .one)
        #expect(receivedSteps[1] == .two)
    }

    @Test("StepEmittable이 다중 구독(Multicast)을 지원하는지 확인")
    @MainActor
    func stepEmittableMulticast() async {
        let viewModel = TestViewModel()
        let stream1 = viewModel.steps
        let stream2 = viewModel.steps

        await confirmation("Both streams received event", expectedCount: 2) { confirm in
            let task1 = Task {
                for await _ in stream1 {
                    confirm()
                    break // 하나만 받고 종료
                }
            }

            let task2 = Task {
                for await _ in stream2 {
                    confirm()
                    break
                }
            }

            viewModel.emit(.one)

            _ = await (task1.result, task2.result)
        }
    }

    @Test("OneStepper가 초기값 하나만 방출하는지 확인")
    @MainActor
    func oneStepper() async {
        let stepper = OneStepper(TestStep.one)
        var receivedSteps: [TestStep] = []

        for await step in stepper.steps {
            receivedSteps.append(step)
            break
        }

        #expect(receivedSteps.count == 1)
        #expect(receivedSteps.first == .one)
    }
}
