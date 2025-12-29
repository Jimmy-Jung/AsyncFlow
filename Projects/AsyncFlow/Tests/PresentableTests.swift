//
//  PresentableTests.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

@Suite("Presentable Tests")
struct PresentableTests {
    // MARK: - Tests

    @Test("Presentable 기본 구현 확인")
    @MainActor
    func defaultImplementation() {
        // Mock Presentable
        final class DefaultPresentable: Presentable {
            #if canImport(UIKit)
                var viewController: PlatformViewController { PlatformViewController() }
            #elseif canImport(AppKit)
                var viewController: PlatformViewController { PlatformViewController() }
            #endif

            var isPresented: Bool = false
            var onDismissed: AsyncStream<Void> { .init { _ in } }
        }

        let presentable = DefaultPresentable()

        // allowStepWhenDismissed 기본값은 true여야 함
        #expect(presentable.allowStepWhenDismissed == true)
    }

    #if canImport(UIKit)
        @Test("UIViewController Presentable 준수 확인")
        @MainActor
        func uIViewControllerPresentable() {
            let viewController = UIViewController()

            // viewController 프로퍼티가 self를 반환하는지 확인
            #expect(viewController.viewController === viewController)

            // 초기 상태
            #expect(viewController.isPresented == false)
            #expect(viewController.allowStepWhenDismissed == true)
        }

        @Test("UIWindow Presentable 준수 확인")
        @MainActor
        func uIWindowPresentable() {
            let window = UIWindow()
            let rootViewController = UIViewController()
            window.rootViewController = rootViewController

            // viewController가 rootViewController를 반환하는지 확인
            #expect(window.viewController === rootViewController)

            // UIWindow는 항상 Presented 상태
            #expect(window.isPresented == true)
            #expect(window.allowStepWhenDismissed == true)
        }
    #endif

    #if canImport(AppKit)
        @Test("NSViewController Presentable 준수 확인")
        @MainActor
        func nSViewControllerPresentable() {
            let viewController = NSViewController()

            #expect(viewController.viewController === viewController)
            #expect(viewController.isPresented == false)
        }

        @Test("NSWindow Presentable 준수 확인")
        @MainActor
        func nSWindowPresentable() {
            let window = NSWindow()
            let contentViewController = NSViewController()
            window.contentViewController = contentViewController

            #expect(window.viewController === contentViewController)
            #expect(window.isPresented == false) // isVisible 기본값 false
            #expect(window.allowStepWhenDismissed == true)
        }
    #endif
}
