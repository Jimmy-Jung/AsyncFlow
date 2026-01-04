//
//  CrossTabNavigationTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing
import UIKit

@MainActor
@Suite("크로스 탭 네비게이션 통합 테스트")
struct CrossTabNavigationTests {
    @Test("TabBarFlow - Tab A에서 Tab B로 전환")
    func switchFromTabAToTabB() async throws {
        // Given
        let tabBarFlow = TabBarFlow()

        // Tab A 초기화
        _ = tabBarFlow.navigate(to: AppStep.appDidStart)

        // Then: Tab A가 선택되어야 함
        #expect(tabBarFlow.tabBarController.selectedIndex == 0)

        // When: Tab B로 전환
        _ = tabBarFlow.navigate(to: AppStep.switchToTabBScreen1)

        // Then: Tab B가 선택되어야 함
        #expect(tabBarFlow.tabBarController.selectedIndex == 1)
    }

    @Test("TabBarFlow - 크로스 탭 네비게이션 시 이전 탭 스택 초기화")
    func crossTabNavigationClearsCurrentStack() async throws {
        // Given
        let tabBarFlow = TabBarFlow()
        _ = tabBarFlow.navigate(to: AppStep.appDidStart)

        // Tab A에 여러 화면 push
        _ = tabBarFlow.navigate(to: TabAStep.navigateToScreen1)
        _ = tabBarFlow.navigate(to: TabAStep.navigateToScreen2)
        _ = tabBarFlow.navigate(to: TabAStep.navigateToScreen3)

        let tabANav = tabBarFlow.tabBarController.viewControllers?[0] as? UINavigationController
        #expect(tabANav?.viewControllers.count == 3)

        // When: Tab B로 전환
        _ = tabBarFlow.navigate(to: AppStep.switchToTabBScreen1)

        // Then: Tab A 스택이 root로 초기화되어야 함
        #expect(tabANav?.viewControllers.count == 1)
        #expect(tabBarFlow.tabBarController.selectedIndex == 1)
    }

    @Test("TabBarFlow - 크로스 탭 네비게이션 후 특정 화면으로 이동")
    func crossTabNavigationToSpecificScreen() async throws {
        // Given
        let tabBarFlow = TabBarFlow()
        _ = tabBarFlow.navigate(to: AppStep.appDidStart)

        // When: Tab B의 Screen3로 이동
        _ = tabBarFlow.navigate(to: AppStep.switchToTabBScreen3)

        // Then
        #expect(tabBarFlow.tabBarController.selectedIndex == 1)

        let tabBNav = tabBarFlow.tabBarController.viewControllers?[1] as? UINavigationController
        #expect(tabBNav?.viewControllers.count == 1)
        #expect(tabBNav?.topViewController is B_3ViewController)
    }

    @Test("TabBarFlow - 여러 번의 크로스 탭 네비게이션")
    func multipleCrossTabNavigations() async throws {
        // Given
        let tabBarFlow = TabBarFlow()
        _ = tabBarFlow.navigate(to: AppStep.appDidStart)

        // When: A → B → A → B
        _ = tabBarFlow.navigate(to: TabAStep.navigateToScreen1)
        #expect(tabBarFlow.tabBarController.selectedIndex == 0)

        _ = tabBarFlow.navigate(to: AppStep.switchToTabBScreen1)
        #expect(tabBarFlow.tabBarController.selectedIndex == 1)

        _ = tabBarFlow.navigate(to: AppStep.switchToTabAScreen2)
        #expect(tabBarFlow.tabBarController.selectedIndex == 0)

        _ = tabBarFlow.navigate(to: AppStep.switchToTabBScreen3)
        #expect(tabBarFlow.tabBarController.selectedIndex == 1)

        // Then: 최종적으로 Tab B, Screen 3
        let tabBNav = tabBarFlow.tabBarController.viewControllers?[1] as? UINavigationController
        #expect(tabBNav?.topViewController is B_3ViewController)
    }
}
