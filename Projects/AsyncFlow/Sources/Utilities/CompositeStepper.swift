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
/// let composite = CompositeStepper([stepper1, stepper2])
/// coordinator.coordinate(flow: appFlow, with: composite)
/// ```
///
/// ## 주의사항
///
/// - 모든 Stepper는 컴파일 타임에 동일한 StepType을 가져야 함
@MainActor
public final class CompositeStepper<S: Step>: Stepper {
    public typealias StepType = S

    /// Step 스트림 (모든 Stepper의 Step 병합)
    public var steps: AsyncStream<S> {
        AsyncStream { continuation in
            for wrapper in stepperWrappers {
                Task {
                    for await step in wrapper.steps {
                        continuation.yield(step)
                    }
                }
            }
        }
    }

    private let stepperWrappers: [StepperWrapper<S>]

    /// CompositeStepper 초기화
    ///
    /// - Parameter steppers: 조합할 Stepper 배열
    public init<S1: Stepper>(_ steppers: [S1]) where S1.StepType == S {
        stepperWrappers = steppers.map { StepperWrapper($0) }
    }
}

// MARK: - Type Eraser

/// Stepper의 타입 지우개
@MainActor
private final class StepperWrapper<S: Step> {
    let steps: AsyncStream<S>

    init<S1: Stepper>(_ stepper: S1) where S1.StepType == S {
        steps = stepper.steps
    }
}
