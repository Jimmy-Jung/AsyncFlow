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
    // MARK: - Properties

    /// 구독 가능한 스트림
    public var stream: AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations[id] = nil
                }
            }
        }
    }

    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// 모든 구독자에게 값 전달
    ///
    /// - Parameter value: 전달할 값
    public func yield(_ value: Element) {
        for continuation in continuations.values {
            continuation.yield(value)
        }
    }

    /// 스트림 종료
    public func finish() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }
}
