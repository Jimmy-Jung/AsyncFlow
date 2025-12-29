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
        /// UIWindow의 rootViewController를 반환
        public var viewController: PlatformViewController {
            return rootViewController ?? UIViewController()
        }

        /// UIWindow는 항상 표시 중으로 간주
        public var isPresented: Bool {
            return true
        }

        /// UIWindow는 dismiss되지 않으므로 빈 스트림
        public var onDismissed: AsyncStream<Void> {
            AsyncStream { _ in
                // UIWindow는 앱 생명주기 동안 유지되므로 never finish
            }
        }

        /// UIWindow는 항상 Step 처리 허용
        public var allowStepWhenDismissed: Bool {
            return true
        }
    }

#endif
