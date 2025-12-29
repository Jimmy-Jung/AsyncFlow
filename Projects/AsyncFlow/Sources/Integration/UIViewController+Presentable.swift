//
//  UIViewController+Presentable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(UIKit)
    import UIKit

    // MARK: - UIViewController + Presentable

    extension UIViewController: Presentable {
        public var viewController: PlatformViewController { self }

        public var isPresented: Bool {
            view.window != nil && !isBeingDismissed
        }

        public var onDismissed: AsyncStream<Void> {
            dismissBridge.stream
        }

        // MARK: - Internal

        var dismissBridge: AsyncStreamBridge<Void> {
            let id = ObjectIdentifier(self)

            if let bridge = PresentableBridgeStorage.shared.getBridge(for: id) {
                return bridge
            }

            let bridge = AsyncStreamBridge<Void>()
            PresentableBridgeStorage.shared.setBridge(bridge, for: id, owner: self)
            return bridge
        }
    }

    // MARK: - Storage

    @MainActor
    private final class PresentableBridgeStorage {
        static let shared = PresentableBridgeStorage()

        private struct WeakBox {
            weak var owner: AnyObject?
            let bridge: AsyncStreamBridge<Void>
        }

        private var storage: [ObjectIdentifier: WeakBox] = [:]

        private init() {}

        func getBridge(for id: ObjectIdentifier) -> AsyncStreamBridge<Void>? {
            cleanupDeallocatedObjects()
            return storage[id]?.bridge
        }

        func setBridge(_ bridge: AsyncStreamBridge<Void>, for id: ObjectIdentifier, owner: AnyObject) {
            storage[id] = WeakBox(owner: owner, bridge: bridge)
        }

        private func cleanupDeallocatedObjects() {
            storage = storage.filter { $0.value.owner != nil }
        }
    }

    // MARK: - Swizzling Support

    public extension UIViewController {
        static func enableAsyncFlowSwizzling() {
            _ = swizzlingToken
        }

        private static let swizzlingToken: Void = {
            let originalSelector = #selector(viewDidDisappear(_:))
            let swizzledSelector = #selector(asyncFlow_viewDidDisappear(_:))

            guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
                  let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector)
            else {
                return
            }

            method_exchangeImplementations(originalMethod, swizzledMethod)
        }()

        @objc func asyncFlow_viewDidDisappear(_ animated: Bool) {
            asyncFlow_viewDidDisappear(animated)

            guard isBeingDismissed || isMovingFromParent else { return }

            Task { @MainActor in
                let id = ObjectIdentifier(self)
                if let bridge = PresentableBridgeStorage.shared.getBridge(for: id) {
                    bridge.yield(())
                }
            }
        }
    }

    public extension UINavigationController {
        func setFlowRoot(_ viewController: UIViewController) {
            setViewControllers([viewController], animated: false)
        }
    }

    public extension UITabBarController {
        func setFlowControllers(_ controllers: [UIViewController]) {
            viewControllers = controllers
        }
    }

#endif
