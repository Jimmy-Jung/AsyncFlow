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
        /// NSViewController 자체를 반환
        public var viewController: PlatformViewController {
            return self
        }

        /// 현재 화면에 표시 중인지 여부
        public var isPresented: Bool {
            return view.window != nil
        }

        /// Dismiss 이벤트 스트림
        ///
        /// NSViewController가 화면에서 사라질 때 알림을 받습니다.
        /// 이 기능이 동작하려면 `NSViewController.enableAsyncFlowSwizzling()`가 호출되어야 합니다.
        public var onDismissed: AsyncStream<Void> {
            dismissBridge.stream
        }

        // MARK: - Internal

        /// Dismiss 이벤트를 전달하는 Bridge
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
        /// AsyncFlow 동작을 위해 viewDidDisappear를 Swizzling합니다.
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
            // 원본 메서드 호출
            asyncFlow_viewDidDisappear()

            // Window가 없거나 닫히는 중이라고 판단되면 이벤트 전달
            // macOS는 isBeingDismissed 같은 명확한 프로퍼티가 없으므로
            // viewDidDisappear 시점에 window가 nil이면 닫힌 것으로 간주합니다.
            if view.window == nil {
                Task { @MainActor in
                    let id = ObjectIdentifier(self)
                    if let bridge = PresentableBridgeStorage.shared.getBridge(for: id) {
                        bridge.yield(())
                    }
                }
            }
        }
    }

#endif
