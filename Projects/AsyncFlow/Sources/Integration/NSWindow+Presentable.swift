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
        /// NSWindow의 contentViewController를 반환
        public var viewController: PlatformViewController {
            return contentViewController ?? NSViewController()
        }

        /// NSWindow는 표시 중(visible)이면 Presented로 간주
        public var isPresented: Bool {
            return isVisible
        }

        /// NSWindow용 Dismiss 스트림 (기본적으로 윈도우는 잘 닫히지 않으므로 빈 스트림 처리)
        /// 필요 시 NSWindowDelegate를 활용하여 구현 가능
        public var onDismissed: AsyncStream<Void> {
            AsyncStream { _ in
                // NSWindow 생명주기는 보통 앱과 같거나 복잡하므로 여기서는 처리하지 않음
            }
        }

        public var allowStepWhenDismissed: Bool {
            return true
        }
    }

#endif
