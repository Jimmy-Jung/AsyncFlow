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
/// @MainActor
/// final class MovieListViewModel: Stepper {
///     @StepEmitter var steps
///
///     var initialStep: Step {
///         MovieStep.movieList
///     }
///
///     func handleAction(_ action: Action) {
///         switch action {
///         case .movieSelected(let id):
///             steps.send(MovieStep.movieDetail(id: id))
///         }
///     }
/// }
/// ```
///
/// ## 내장 구현체
///
/// - `OneStepper`: 초기 Step 하나만 방출
/// - `CompositeStepper`: 여러 Stepper를 조합
/// - `DefaultStepper`: 기본 Stepper (NoneStep 방출)
@MainActor
public protocol Stepper: AnyObject {
    /// Step을 방출하는 Subject
    ///
    /// AsyncPassthroughSubject를 사용하여 Step을 방출합니다.
    var steps: AsyncPassthroughSubject<Step> { get }

    /// 초기 Step
    ///
    /// FlowCoordinator가 이 Stepper를 등록할 때 즉시 방출되는 Step입니다.
    /// 기본값은 NoneStep()입니다.
    var initialStep: Step { get }

    /// Step 방출 준비 완료 시 호출
    ///
    /// FlowCoordinator가 이 Stepper를 구독하기 시작할 때 호출됩니다.
    /// 초기화 시점에 필요한 로직을 여기에 구현할 수 있습니다.
    func readyToEmitSteps()
}

// MARK: - Default Implementation

public extension Stepper {
    var initialStep: Step {
        NoneStep()
    }

    func readyToEmitSteps() {}
}

// MARK: - Property Wrapper

/// Step을 방출하는 Subject를 편리하게 선언하기 위한 Property Wrapper
///
/// ## 사용 예시
///
/// ```swift
/// @MainActor
/// final class MovieListViewModel: Stepper {
///     @Steps var steps
///
///     func handleAction(_ action: Action) {
///         steps.send(MovieStep.movieDetail(id: id))
///     }
/// }
/// ```
@propertyWrapper
@MainActor
public struct Steps {
    private let subject = AsyncPassthroughSubject<Step>()

    public var wrappedValue: AsyncPassthroughSubject<Step> {
        subject
    }

    public init() {}
}

// MARK: - AsyncPassthroughSubject

/// RxSwift의 PublishRelay와 유사한 역할을 하는 AsyncStream 기반 Subject
///
/// 여러 구독자가 동일한 스트림을 구독할 수 있습니다.
/// 구독 전에 전송된 값은 버퍼에 저장되어 첫 번째 구독자가 받을 수 있습니다.
@MainActor
public final class AsyncPassthroughSubject<Element: Sendable> {
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var buffer: [Element] = []
    private let bufferSize: Int = 1 // initialStep만 저장
    private var isFinished = false

    public init() {}

    /// Step 스트림
    public var stream: AsyncStream<Element> {
        AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }

            if self.isFinished {
                continuation.finish()
                return
            }

            // 구독 시 버퍼의 값들을 먼저 전송
            for bufferedValue in self.buffer {
                continuation.yield(bufferedValue)
            }

            let id = UUID()
            self.continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations[id] = nil
                }
            }
        }
    }

    /// 값 방출
    public func send(_ value: Element) {
        guard !isFinished else { return }

        if continuations.isEmpty {
            // 구독자가 없으면 버퍼에 저장
            buffer.append(value)
            // 버퍼 크기 제한 (initialStep만 유지)
            if buffer.count > bufferSize {
                buffer.removeFirst()
            }
        } else {
            // 구독자가 있으면 버퍼를 비우고 모두에게 전송
            buffer.removeAll()
            for continuation in continuations.values {
                continuation.yield(value)
            }
        }
    }

    /// 스트림 종료
    public func finish() {
        guard !isFinished else { return }
        isFinished = true
        buffer.removeAll()
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }
}
