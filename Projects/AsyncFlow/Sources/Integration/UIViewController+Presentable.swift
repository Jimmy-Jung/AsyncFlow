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
        /// UIViewController 자체를 반환
        public var viewController: PlatformViewController {
            return self
        }

        /// 현재 화면에 표시 중인지 여부
        public var isPresented: Bool {
            return view.window != nil && !isBeingDismissed
        }

        /// Dismiss 이벤트 스트림
        ///
        /// UIViewController가 화면에서 사라질 때 알림을 받습니다.
        /// 이 기능이 동작하려면 `UIViewController.swizzleViewDidDisappear()`가 호출되어야 합니다.
        /// (일반적으로 AsyncFlow 초기화 시 자동 호출됨)
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

    public extension UIViewController {
        /// AsyncFlow 동작을 위해 viewDidDisappear를 Swizzling합니다.
        /// 이 메서드는 앱 시작 시 한 번만 호출하면 됩니다.
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
            // 원본 메서드 호출 (Swizzling 되었으므로 이 호출이 원본을 실행함)
            asyncFlow_viewDidDisappear(animated)

            // Dismiss 체크
            if isBeingDismissed || isMovingFromParent {
                // Bridge가 생성된 경우에만 이벤트 전달
                Task { @MainActor in
                    let id = ObjectIdentifier(self)
                    if let bridge = PresentableBridgeStorage.shared.getBridge(for: id) {
                        bridge.yield(())
                    }
                }
            }
        }
    }

    // MARK: - UINavigationController + Flow Support

    public extension UINavigationController {
        /// NavigationController의 root를 설정하는 편의 메서드
        func setFlowRoot(_ viewController: UIViewController) {
            setViewControllers([viewController], animated: false)
        }
    }

    // MARK: - UITabBarController + Flow Support

    public extension UITabBarController {
        /// TabBarController에 여러 Flow 설정하는 편의 메서드
        func setFlowControllers(_ controllers: [UIViewController]) {
            viewControllers = controllers
        }
    }

#endif
