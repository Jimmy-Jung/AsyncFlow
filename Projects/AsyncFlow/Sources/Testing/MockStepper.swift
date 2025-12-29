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
///     let mockStepper = MockStepper<MovieStep>()
///     var receivedSteps: [MovieStep] = []
///
///     Task {
///         for await step in mockStepper.steps {
///             receivedSteps.append(step)
///         }
///     }
///
///     // Step 방출
///     mockStepper.emit(.movieList)
///     mockStepper.emit(.movieDetail(id: 1))
///
///     try await Task.sleep(for: .milliseconds(100))
///
///     #expect(receivedSteps == [.movieList, .movieDetail(id: 1)])
/// }
/// ```
@MainActor
public final class MockStepper<S: Step>: Stepper {
    public typealias StepType = S

    @StepEmitter public var stepEmitter: StepEmitter<S>
    public private(set) var emittedSteps: [S] = []

    public var onObservationStart: (() -> Void)?
    private var hasNotifiedObservation = false

    public init() {}

    public var steps: AsyncStream<S> {
        if !hasNotifiedObservation {
            hasNotifiedObservation = true
            onObservationStart?()
        }
        return stepEmitter.stream
    }

    public func emit(_ step: S) {
        emittedSteps.append(step)
        stepEmitter.emit(step)
    }

    public func emit(_ steps: [S]) {
        steps.forEach(emit)
    }

    public func emit(_ step: S, waitFor duration: TimeInterval) async {
        emit(step)
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    public func reset() {
        emittedSteps.removeAll()
        hasNotifiedObservation = false
    }
}
