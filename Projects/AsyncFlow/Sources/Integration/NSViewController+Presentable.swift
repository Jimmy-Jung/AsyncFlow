//
//  NSViewController+Presentable.swift
//  AsyncFlow
//
//  Created by 정준영 on 2025. 12. 29.
//

#if canImport(AppKit)
    import AppKit

    // MARK: - NSViewController + Presentable

    extension NSViewController: Presentable {
        public var viewController: PlatformViewController { self }

        public var isPresented: Bool {
            view.window != nil
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

    public extension NSViewController {
        static func enableAsyncFlowSwizzling() {
            _ = swizzlingToken
        }

        private static let swizzlingToken: Void = {
            let originalSelector = #selector(viewDidDisappear)
            let swizzledSelector = #selector(asyncFlow_viewDidDisappear)

            guard let originalMethod = class_getInstanceMethod(NSViewController.self, originalSelector),
                  let swizzledMethod = class_getInstanceMethod(NSViewController.self, swizzledSelector)
            else {
                return
            }

            method_exchangeImplementations(originalMethod, swizzledMethod)
        }()

        @objc func asyncFlow_viewDidDisappear() {
            asyncFlow_viewDidDisappear()

            guard view.window == nil else { return }

            Task { @MainActor in
                let id = ObjectIdentifier(self)
                if let bridge = PresentableBridgeStorage.shared.getBridge(for: id) {
                    bridge.yield(())
                }
            }
        }
    }

#endif
