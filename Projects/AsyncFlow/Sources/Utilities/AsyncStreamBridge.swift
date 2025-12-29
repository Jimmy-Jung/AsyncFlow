//
//  AsyncStreamBridge.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

/// AsyncStream을 브로드캐스트 가능하게 만드는 브릿지
///
/// Swift의 AsyncStream은 기본적으로 단일 구독자만 지원합니다.
/// AsyncStreamBridge는 여러 구독자가 동일한 스트림을 구독할 수 있게 합니다.
///
/// ## 사용 예시
///
/// ```swift
/// class EventPublisher {
///     private let bridge = AsyncStreamBridge<String>()
///
///     var events: AsyncStream<String> {
///         bridge.stream
///     }
///
///     func publish(_ event: String) {
///         bridge.yield(event)
///     }
/// }
///
/// // 여러 곳에서 구독 가능
/// Task {
///     for await event in publisher.events {
///         print("Subscriber 1: \(event)")
///     }
/// }
///
/// Task {
///     for await event in publisher.events {
///         print("Subscriber 2: \(event)")
///     }
/// }
/// ```
@MainActor
public final class AsyncStreamBridge<Element: Sendable> {
    public var stream: AsyncStream<Element> {
        AsyncStream { [weak self] continuation in
            self?.setupContinuation(continuation)
        }
    }

    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
    private var isFinished = false

    public init() {}

    private func setupContinuation(_ continuation: AsyncStream<Element>.Continuation) {
        guard !isFinished else {
            continuation.finish()
            return
        }

        let id = UUID()
        continuations[id] = continuation

        continuation.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.continuations[id] = nil
            }
        }
    }

    public func yield(_ value: Element) {
        guard !isFinished else { return }
        continuations.values.forEach { $0.yield(value) }
    }

    public func finish() {
        guard !isFinished else { return }
        isFinished = true
        continuations.values.forEach { $0.finish() }
        continuations.removeAll()
    }
}
