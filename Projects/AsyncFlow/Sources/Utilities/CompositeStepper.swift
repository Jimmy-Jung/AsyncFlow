//
//  CompositeStepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// 여러 Stepper를 조합하는 Stepper
///
/// 여러 ViewModel이나 Stepper의 Step을 하나의 스트림으로 병합합니다.
///
/// ## 사용 예시
///
/// ```swift
/// let stepper1 = MovieListViewModel()
/// let stepper2 = WatchedListViewModel()
///
/// let composite = CompositeStepper(steppers: [stepper1, stepper2])
/// coordinator.coordinate(flow: appFlow, with: composite)
/// ```
///
/// ## 주의사항
///
/// - 모든 내부 Stepper의 initialStep이 순차적으로 방출됩니다.
/// - 이후 모든 Stepper의 Step이 병합되어 방출됩니다.
@MainActor
public final class CompositeStepper: FlowStepper {
    public let steps = AsyncReplaySubject<Step>(bufferSize: 1)

    private let innerSteppers: [FlowStepper]
    private var observationTasks: [Task<Void, Never>] = []

    /// CompositeStepper 초기화
    ///
    /// - Parameter steppers: 조합할 FlowStepper 배열
    public init(steppers: [FlowStepper]) {
        innerSteppers = steppers
    }

    public func readyToEmitSteps() {
        // 모든 내부 Stepper의 initialStep 방출
        for stepper in innerSteppers {
            let initialStep = stepper.initialStep
            if !(initialStep is NoneStep) {
                steps.send(initialStep)
            }
        }

        // 모든 내부 Stepper의 Step 구독
        for stepper in innerSteppers {
            let task = Task { @MainActor [weak self, weak stepper] in
                guard let stepper = stepper else { return }

                stepper.readyToEmitSteps()

                for await step in stepper.steps.stream {
                    guard !Task.isCancelled else { break }

                    if step is NoneStep { continue }
                    self?.steps.send(step)
                }
            }
            observationTasks.append(task)
        }
    }

    deinit {
        for task in observationTasks {
            task.cancel()
        }
    }
}
