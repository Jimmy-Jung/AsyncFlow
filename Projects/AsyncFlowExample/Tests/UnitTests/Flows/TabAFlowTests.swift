//
//  TabAFlowTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing

@MainActor
@Suite("TabA Flow Tests")
struct TabAFlowTests {
    @Test("TabAFlow - Screen1 네비게이션")
    func testNavigateToScreen1() async throws {
        // Given
        let flow = TabAFlow()
        let step = TabAStep.navigateToScreen1

        // When
        let contributors = flow.navigate(to: step)

        // Then
        #expect(flow.navigationController.viewControllers.count == 1)
        #expect(flow.navigationController.viewControllers.first is A_1ViewController)

        // Contributors 확인
        switch contributors {
        case .one:
            break // Success
        default:
            Issue.record("Expected .one contributor")
        }
    }

    @Test("TabAFlow - 여러 화면 순차 네비게이션")
    func sequentialNavigation() async throws {
        // Given
        let flow = TabAFlow()

        // When: A-1 → A-2 → A-3
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // Then
        #expect(flow.navigationController.viewControllers.count == 3)
        #expect(flow.navigationController.viewControllers[0] is A_1ViewController)
        #expect(flow.navigationController.viewControllers[1] is A_2ViewController)
        #expect(flow.navigationController.viewControllers[2] is A_3ViewController)
    }

    @Test("TabAFlow - Pop ViewController")
    func testPopViewController() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        #expect(flow.navigationController.viewControllers.count == 3)

        // When: 1단계 뒤로
        _ = flow.navigate(to: TabAStep.popViewController(count: 1))

        // Then
        #expect(flow.navigationController.viewControllers.count == 2)
        #expect(flow.navigationController.topViewController is A_2ViewController)
    }

    @Test("TabAFlow - Pop To Root")
    func testPopToRoot() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)
        _ = flow.navigate(to: TabAStep.navigateToScreen4)

        #expect(flow.navigationController.viewControllers.count == 4)

        // When
        _ = flow.navigate(to: TabAStep.popToRoot)

        // Then
        #expect(flow.navigationController.viewControllers.count == 1)
        #expect(flow.navigationController.topViewController is A_1ViewController)
    }

    @Test("TabAFlow - 메타데이터 추적")
    func metadataTracking() async throws {
        // Given
        let flow = TabAFlow()

        // When
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)

        // Then
        let metadata = flow.currentStackMetadata
        #expect(metadata.count == 2)
        #expect(metadata[0].displayName == "A-1")
        #expect(metadata[1].displayName == "A-2")
    }
}
