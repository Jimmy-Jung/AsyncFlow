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

    @Test("MockPresentable 기본 동작 확인")
    @MainActor
    func mockPresentableBasics() async {
        let presentable = MockPresentable()

        // 초기 상태
        #expect(presentable.isPresented == true)

        // visible 스트림 확인
        let visibilityTask = Task {
            var values: [Bool] = []
            for await visible in presentable.isVisibleStream {
                values.append(visible)
                if values.count == 1 { break }
            }
            return values
        }

        // 구독이 설정될 시간을 줌
        await Task.yield()
        
        presentable.setVisible(true)
        let result = await visibilityTask.value
        #expect(result == [true])
    }

    @Test("MockPresentable dismiss 동작 확인")
    @MainActor
    func mockPresentableDismiss() async {
        let presentable = MockPresentable()

        let dismissTask = Task {
            var dismissed = false
            for await _ in presentable.onDismissed {
                dismissed = true
                break
            }
            return dismissed
        }

        // 구독이 설정될 시간을 줌
        await Task.yield()
        
        // dismiss 호출
        presentable.dismiss()

        let result = await dismissTask.value
        #expect(result == true)
        #expect(presentable.isPresented == false)
    }

    #if canImport(UIKit)
        @Test("UIViewController Presentable 준수 확인")
        @MainActor
        func uIViewControllerPresentable() async {
            let viewController = UIViewController()

            // isVisibleStream과 onDismissed 스트림이 있는지 확인
            _ = viewController.isVisibleStream
            _ = viewController.onDismissed

            // 테스트 통과 (크래시 없이 접근 가능)
            #expect(true)
        }

        @Test("UIWindow Presentable 준수 확인")
        @MainActor
        func uIWindowPresentable() async {
            let window = UIWindow()

            // isVisibleStream과 onDismissed 스트림이 있는지 확인
            _ = window.isVisibleStream
            _ = window.onDismissed

            // 테스트 통과 (크래시 없이 접근 가능)
            #expect(true)
        }
    #endif

    #if canImport(AppKit)
        @Test("NSViewController Presentable 준수 확인")
        @MainActor
        func nSViewControllerPresentable() async {
            let viewController = NSViewController()

            // isVisibleStream과 onDismissed 스트림이 있는지 확인
            _ = viewController.isVisibleStream
            _ = viewController.onDismissed

            // 테스트 통과 (크래시 없이 접근 가능)
            #expect(true)
        }

        @Test("NSWindow Presentable 준수 확인")
        @MainActor
        func nSWindowPresentable() async {
            let window = NSWindow()

            // isVisibleStream과 onDismissed 스트림이 있는지 확인
            _ = window.isVisibleStream
            _ = window.onDismissed

            // 테스트 통과 (크래시 없이 접근 가능)
            #expect(true)
        }
    #endif
}
