//
//  FlowStepper.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// Step을 방출하는 주체를 나타내는 프로토콜
///
/// FlowStepper는 AsyncStream을 통해 Step을 비동기적으로 방출합니다.
/// 주로 ViewModel이 FlowStepper 역할을 합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @MainActor
/// final class MovieListViewModel: FlowStepper {
///     @Steps var steps
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
/// - `CompositeStepper`: 여러 FlowStepper를 조합
/// - `DefaultStepper`: 기본 FlowStepper (NoneStep 방출)
@MainActor
public protocol FlowStepper: AnyObject {
    /// Step을 방출하는 Subject
    ///
    /// AsyncReplaySubject를 사용하여 Step을 방출합니다.
    var steps: AsyncReplaySubject<Step> { get }

    /// 초기 Step
    ///
    /// FlowCoordinator가 이 FlowStepper를 등록할 때 즉시 방출되는 Step입니다.
    /// 기본값은 NoneStep()입니다.
    var initialStep: Step { get }

    /// Step 방출 준비 완료 시 호출
    ///
    /// FlowCoordinator가 이 FlowStepper를 구독하기 시작할 때 호출됩니다.
    /// 초기화 시점에 필요한 로직을 여기에 구현할 수 있습니다.
    func readyToEmitSteps()
}

// MARK: - Default Implementation

public extension FlowStepper {
    var initialStep: Step {
        NoneStep()
    }

    func readyToEmitSteps() {}
}

// MARK: - Property Wrapper

/// Step을 방출하는 Subject를 편리하게 선언하기 위한 Property Wrapper
///
/// AsyncReplaySubject를 사용하여 initialStep을 버퍼링합니다.
///
/// ## 사용 예시
///
/// ```swift
/// @MainActor
/// final class MovieListViewModel: FlowStepper {
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
    private let subject = AsyncReplaySubject<Step>(bufferSize: 1)

    public var wrappedValue: AsyncReplaySubject<Step> {
        subject
    }

    public init() {}
}

// MARK: - AsyncPassthroughSubject

/// RxSwift의 PublishRelay와 유사한 역할을 하는 AsyncStream 기반 Subject
///
/// 여러 구독자가 동일한 스트림을 구독할 수 있습니다.
/// 구독 전에 전송된 값은 무시되고, 구독 후 전송된 값만 받습니다.
@MainActor
public final class AsyncPassthroughSubject<Element: Sendable> {
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
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

        // 구독자가 있으면 모두에게 전송 (구독자가 없으면 무시)
        for continuation in continuations.values {
            continuation.yield(value)
        }
    }

    /// 스트림 종료
    public func finish() {
        guard !isFinished else { return }
        isFinished = true
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }
}

// MARK: - AsyncReplaySubject

/// 마지막 N개의 값을 버퍼링하는 AsyncStream 기반 Subject
///
/// 여러 구독자가 동일한 스트림을 구독할 수 있습니다.
/// 구독 전에 전송된 값은 버퍼에 저장되어 새 구독자가 받을 수 있습니다.
/// initialStep을 위해 사용됩니다.
@MainActor
public final class AsyncReplaySubject<Element: Sendable> {
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var buffer: [Element] = []
    private let bufferSize: Int
    private var isFinished = false

    /// - Parameter bufferSize: 버퍼링할 값의 개수 (기본값: 1)
    public init(bufferSize: Int = 1) {
        self.bufferSize = bufferSize
    }

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

        // 버퍼에 저장
        buffer.append(value)
        if buffer.count > bufferSize {
            buffer.removeFirst()
        }

        // 구독자가 있으면 모두에게 전송
        for continuation in continuations.values {
            continuation.yield(value)
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
