//
//  Stepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// Step을 방출하는 주체를 나타내는 프로토콜
///
/// Stepper는 AsyncStream을 통해 Step을 비동기적으로 방출합니다.
/// 주로 ViewModel이 Stepper 역할을 합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @AsyncViewModel
/// final class MovieListViewModel: StepEmittable {
///     typealias StepType = MovieStep
///     var stepContinuation: AsyncStream<MovieStep>.Continuation?
///
///     func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
///         switch action {
///         case .movieSelected(let id):
///             emit(.movieDetail(id: id))  // Step 방출
///             return []
///         }
///     }
/// }
/// ```
///
/// ## 내장 구현체
///
/// - `OneStepper`: 초기 Step 하나만 방출
/// - `CompositeStepper`: 여러 Stepper를 조합
/// - `StepEmittable`: AsyncViewModel과 통합용
@MainActor
public protocol Stepper<StepType>: AnyObject {
    /// Step의 타입
    associatedtype StepType: Step

    /// Step을 방출하는 비동기 스트림
    var steps: AsyncStream<StepType> { get }
}
