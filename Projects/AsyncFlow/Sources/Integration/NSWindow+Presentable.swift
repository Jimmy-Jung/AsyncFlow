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
        public var viewController: PlatformViewController {
            contentViewController ?? NSViewController()
        }

        public var isPresented: Bool { isVisible }

        public var onDismissed: AsyncStream<Void> {
            AsyncStream { _ in }
        }

        public var allowStepWhenDismissed: Bool { true }
    }

#endif
