//
//  MockStepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// 테스트용 Stepper
///
/// Step을 수동으로 방출하고 스트림을 제어할 수 있습니다.
///
/// ## 사용 예시
///
/// ```swift
/// @Test
/// func testStepEmission() async {
///     let mockStepper = MockStepper()
///     mockStepper.setInitialStep(MovieStep.movieList)
///
///     var receivedSteps: [Step] = []
///
///     Task {
///         for await step in mockStepper.steps.stream {
///             receivedSteps.append(step)
///         }
///     }
///
///     // Step 방출
///     mockStepper.emit(MovieStep.movieDetail(id: 1))
///
///     try await Task.sleep(for: .milliseconds(100))
///
///     #expect(receivedSteps.count == 1)
/// }
/// ```
@MainActor
public final class MockStepper: FlowStepper {
    public let steps = AsyncReplaySubject<Step>(bufferSize: 1)
    public private(set) var emittedSteps: [Step] = []

    private var _initialStep: Step = NoneStep()

    public var onObservationStart: (() -> Void)?
    private var hasNotifiedObservation = false

    public init() {}

    public var initialStep: Step {
        _initialStep
    }

    public func setInitialStep(_ step: Step) {
        _initialStep = step
    }

    public func readyToEmitSteps() {
        if !hasNotifiedObservation {
            hasNotifiedObservation = true
            onObservationStart?()
        }
    }

    public func emit(_ step: Step) {
        emittedSteps.append(step)
        steps.send(step)
    }

    public func emit(_ steps: [Step]) {
        steps.forEach(emit)
    }

    public func emit(_ step: Step, waitFor duration: TimeInterval) async {
        emit(step)
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    public func reset() {
        emittedSteps.removeAll()
        hasNotifiedObservation = false
        _initialStep = NoneStep()
    }
}
