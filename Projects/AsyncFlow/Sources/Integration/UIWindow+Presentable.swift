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
        public var viewController: PlatformViewController {
            rootViewController ?? UIViewController()
        }

        public var isPresented: Bool { true }

        public var onDismissed: AsyncStream<Void> {
            AsyncStream { _ in }
        }

        public var allowStepWhenDismissed: Bool { true }
    }

#endif
