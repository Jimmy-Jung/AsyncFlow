//
//  TabBarFlowTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing

@MainActor
@Suite("TabBar Flow Tests")
struct TabBarFlowTests {
    @Test("TabBarFlow - 초기화 확인")
    func initialization() async throws {
        // Given & When
        let flow = TabBarFlow()

        // Then
        #expect(flow.tabBarController.viewControllers?.count == 2)
        #expect(flow.tabBarController.viewControllers?[0].tabBarItem.tag == 0)
        #expect(flow.tabBarController.viewControllers?[1].tabBarItem.tag == 1)
    }

    @Test("TabBarFlow - 앱 시작")
    func appStart() async throws {
        // Given
        let flow = TabBarFlow()
        let step = AppStep.appDidStart

        // When
        let contributors = flow.navigate(to: step)

        // Then
        switch contributors {
        case let .multiple(list):
            #expect(list.count == 2) // TabA, TabB
        default:
            Issue.record("Expected .multiple contributors")
        }
    }

    @Test("TabBarFlow - 크로스 탭 네비게이션 (A → B)")
    func crossTabNavigation_AtoB() async throws {
        // Given
        let flow = TabBarFlow()
        flow.tabBarController.selectedIndex = 0 // Tab A 선택

        // When: Tab B의 Screen 3로 이동
        _ = flow.navigate(to: AppStep.switchToTabBScreen3)

        // Then: Tab B가 선택되어야 함
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15초 대기
        #expect(flow.tabBarController.selectedIndex == 1)
    }

    @Test("TabBarFlow - 크로스 탭 네비게이션 (B → A)")
    func crossTabNavigation_BtoA() async throws {
        // Given
        let flow = TabBarFlow()
        flow.tabBarController.selectedIndex = 1 // Tab B 선택

        // When: Tab A의 Screen 2로 이동
        _ = flow.navigate(to: AppStep.switchToTabAScreen2)

        // Then: Tab A가 선택되어야 함
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15초 대기
        #expect(flow.tabBarController.selectedIndex == 0)
    }
}
