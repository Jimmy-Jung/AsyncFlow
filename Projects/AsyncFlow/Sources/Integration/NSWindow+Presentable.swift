//
//  NSWindow+Presentable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(AppKit)
    import AppKit

    // MARK: - NSWindow + Presentable

    extension NSWindow: Presentable {
        /// Window visibility 스트림
        public var isVisibleStream: AsyncStream<Bool> {
            AsyncStream { [weak self] continuation in
                continuation.yield(self?.isVisible ?? false)
            }
        }

        /// Window는 dismiss되지 않음
        public var onDismissed: AsyncStream<Void> {
            AsyncStream { _ in }
        }
    }

#endif
