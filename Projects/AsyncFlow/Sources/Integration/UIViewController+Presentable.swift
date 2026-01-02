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
        /// Presentable이 표시될 때 true를 방출하는 스트림
        public var isVisibleStream: AsyncStream<Bool> {
            visibilityBridge.stream
        }

        /// Presentable이 dismiss될 때 알림을 받는 스트림
        public var onDismissed: AsyncStream<Void> {
            dismissBridge.stream
        }

        // MARK: - Internal

        var visibilityBridge: AsyncPassthroughSubject<Bool> {
            let id = ObjectIdentifier(self)

            if let bridge = PresentableBridgeStorage.shared.getVisibilityBridge(for: id) {
                return bridge
            }

            let bridge = AsyncPassthroughSubject<Bool>()
            PresentableBridgeStorage.shared.setVisibilityBridge(bridge, for: id, owner: self)
            return bridge
        }

        var dismissBridge: AsyncPassthroughSubject<Void> {
            let id = ObjectIdentifier(self)

            if let bridge = PresentableBridgeStorage.shared.getDismissBridge(for: id) {
                return bridge
            }

            let bridge = AsyncPassthroughSubject<Void>()
            PresentableBridgeStorage.shared.setDismissBridge(bridge, for: id, owner: self)
            return bridge
        }
    }

    // MARK: - Storage

    @MainActor
    private final class PresentableBridgeStorage {
        static let shared = PresentableBridgeStorage()

        private struct WeakBox {
            weak var owner: AnyObject?
            let visibilityBridge: AsyncPassthroughSubject<Bool>?
            let dismissBridge: AsyncPassthroughSubject<Void>?
        }

        private var storage: [ObjectIdentifier: WeakBox] = [:]

        private init() {}

        func getVisibilityBridge(for id: ObjectIdentifier) -> AsyncPassthroughSubject<Bool>? {
            cleanupDeallocatedObjects()
            return storage[id]?.visibilityBridge
        }

        func getDismissBridge(for id: ObjectIdentifier) -> AsyncPassthroughSubject<Void>? {
            cleanupDeallocatedObjects()
            return storage[id]?.dismissBridge
        }

        func setVisibilityBridge(_ bridge: AsyncPassthroughSubject<Bool>, for id: ObjectIdentifier, owner: AnyObject) {
            let existing = storage[id]
            storage[id] = WeakBox(
                owner: owner,
                visibilityBridge: bridge,
                dismissBridge: existing?.dismissBridge
            )
        }

        func setDismissBridge(_ bridge: AsyncPassthroughSubject<Void>, for id: ObjectIdentifier, owner: AnyObject) {
            let existing = storage[id]
            storage[id] = WeakBox(
                owner: owner,
                visibilityBridge: existing?.visibilityBridge,
                dismissBridge: bridge
            )
        }

        private func cleanupDeallocatedObjects() {
            storage = storage.filter { _, box in box.owner != nil }
        }
    }

    // MARK: - Swizzling Support

    public extension UIViewController {
        static func enableAsyncFlowSwizzling() {
            _ = swizzlingToken
        }

        private static let swizzlingToken: Void = {
            // viewDidAppear swizzling
            let originalAppearSelector = #selector(viewDidAppear(_:))
            let swizzledAppearSelector = #selector(asyncFlow_viewDidAppear(_:))

            if let originalMethod = class_getInstanceMethod(UIViewController.self, originalAppearSelector),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledAppearSelector)
            {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }

            // viewDidDisappear swizzling
            let originalDisappearSelector = #selector(viewDidDisappear(_:))
            let swizzledDisappearSelector = #selector(asyncFlow_viewDidDisappear(_:))

            if let originalMethod = class_getInstanceMethod(UIViewController.self, originalDisappearSelector),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledDisappearSelector)
            {
            method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }()

        @objc func asyncFlow_viewDidAppear(_ animated: Bool) {
            asyncFlow_viewDidAppear(animated)

            Task { @MainActor in
                let id = ObjectIdentifier(self)
                if let bridge = PresentableBridgeStorage.shared.getVisibilityBridge(for: id) {
                    bridge.send(true)
                }
            }
        }

        @objc func asyncFlow_viewDidDisappear(_ animated: Bool) {
            asyncFlow_viewDidDisappear(animated)

            Task { @MainActor in
                let id = ObjectIdentifier(self)

                // visibility 업데이트
                if let visibilityBridge = PresentableBridgeStorage.shared.getVisibilityBridge(for: id) {
                    visibilityBridge.send(false)
                }

                // dismiss 체크
                guard isBeingDismissed || isMovingFromParent else { return }

                if let dismissBridge = PresentableBridgeStorage.shared.getDismissBridge(for: id) {
                    dismissBridge.send(())
                }
            }
        }
    }

    // MARK: - UINavigationController Convenience

    public extension UINavigationController {
        /// Flow의 root ViewController 설정
        func setFlowRoot(_ viewController: UIViewController) {
            setViewControllers([viewController], animated: false)
        }
    }

    // MARK: - UITabBarController Convenience

    public extension UITabBarController {
        /// Flow의 탭 ViewController들 설정
        func setFlowControllers(_ controllers: [UIViewController]) {
            viewControllers = controllers
        }
    }

#endif
