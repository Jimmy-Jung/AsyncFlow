//
//  UIWindow+Presentable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(UIKit)
    import UIKit

    // MARK: - UIWindow + Presentable

    extension UIWindow: Presentable {
        /// Window는 항상 visible
        public var isVisibleStream: AsyncStream<Bool> {
            AsyncStream { continuation in
                continuation.yield(true)
            }
        }

        /// Window는 dismiss되지 않음
        public var onDismissed: AsyncStream<Void> {
            AsyncStream { _ in }
        }
    }

#endif
