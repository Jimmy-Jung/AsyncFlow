//
//  Stepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

// MARK: - StepEmitter Property Wrapper

/// Step을 방출하는 프로퍼티 래퍼
///
/// Stepper 프로토콜을 채택하는 타입에서 사용합니다.
/// AsyncStreamBridge를 내부적으로 관리하여 Step 방출 로직을 캡슐화합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @MainActor
/// final class MovieListViewModel: Stepper {
///     typealias StepType = MovieStep
///     @StepEmitter var stepEmitter: StepEmitter<MovieStep>
/// }
/// ```
@propertyWrapper
@MainActor
public final class StepEmitter<StepType: Step> {
    private let bridge = AsyncStreamBridge<StepType>()

    public init() {}

    public var wrappedValue: StepEmitter<StepType> { self }
    public var projectedValue: StepEmitter<StepType> { self }

    public var stream: AsyncStream<StepType> {
        bridge.stream
    }

    public func emit(_ step: StepType) {
        bridge.yield(step)
    }
}

// MARK: - Stepper Protocol

/// Step을 방출하는 주체를 나타내는 프로토콜
///
/// Stepper는 AsyncStream을 통해 Step을 비동기적으로 방출합니다.
/// 주로 ViewModel이 Stepper 역할을 합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @MainActor
/// final class MovieListViewModel: Stepper {
///     typealias StepType = MovieStep
///     @StepEmitter var stepEmitter: StepEmitter<MovieStep>
///
///     func handleAction(_ action: Action) {
///         switch action {
///         case .movieSelected(let id):
///             emit(.movieDetail(id: id))  // Step 방출
///         }
///     }
/// }
/// ```
///
/// ## 내장 구현체
///
/// - `OneStepper`: 초기 Step 하나만 방출
/// - `CompositeStepper`: 여러 Stepper를 조합
/// - `MockStepper`: 테스트용 Stepper
@MainActor
public protocol Stepper<StepType>: AnyObject {
    /// Step의 타입
    associatedtype StepType: Step

    /// Step Emitter
    ///
    /// @StepEmitter 프로퍼티 래퍼로 선언해야 합니다.
    /// OneStepper, CompositeStepper 등 특수한 구현체는 steps를 override할 수 있습니다.
    var stepEmitter: StepEmitter<StepType> { get }

    /// Step을 방출하는 비동기 스트림
    var steps: AsyncStream<StepType> { get }

    /// Step 방출
    ///
    /// - Parameter step: 방출할 Step
    func emit(_ step: StepType)
}

public extension Stepper {
    var steps: AsyncStream<StepType> {
        stepEmitter.stream
    }

    func emit(_ step: StepType) {
        stepEmitter.emit(step)
    }
}
