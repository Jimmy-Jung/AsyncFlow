//
//  StackConsistencyTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing
import UIKit

@MainActor
@Suite("스택 일관성 테스트")
struct StackConsistencyTests {
    @Test("NavigationFlow - viewControllers와 metadata 동기화")
    func viewControllersAndMetadataSync() async throws {
        // Given
        let flow = TabAFlow()

        // When: 여러 화면 push
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // Then: viewControllers 수와 metadata 수가 일치해야 함
        let vcCount = flow.navigationController.viewControllers.count
        let metadataCount = flow.currentStackMetadata.count
        #expect(vcCount == metadataCount)
        #expect(vcCount == 3)
    }

    @Test("NavigationFlow - Pop 후에도 동기화 유지")
    func syncAfterPop() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)
        _ = flow.navigate(to: TabAStep.navigateToScreen4)

        // When: Pop
        _ = flow.navigate(to: TabAStep.popViewController(count: 2))

        // Then
        let vcCount = flow.navigationController.viewControllers.count
        let metadataCount = flow.currentStackMetadata.count
        #expect(vcCount == metadataCount)
        #expect(vcCount == 2)
    }

    @Test("NavigationFlow - PopToRoot 후 동기화")
    func syncAfterPopToRoot() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)
        _ = flow.navigate(to: TabAStep.navigateToScreen4)
        _ = flow.navigate(to: TabAStep.navigateToScreen5)

        // When: PopToRoot
        _ = flow.navigate(to: TabAStep.popToRoot)

        // Then
        let vcCount = flow.navigationController.viewControllers.count
        let metadataCount = flow.currentStackMetadata.count
        #expect(vcCount == metadataCount)
        #expect(vcCount == 1)
    }

    @Test("NavigationFlow - 시스템 pop 후에도 동기화 유지")
    func syncAfterSystemPop() async throws {
        // Given
        let flow = TabAFlow()
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        _ = flow.navigate(to: TabAStep.navigateToScreen3)

        // When: 시스템 pop 시뮬레이션
        flow.navigationController.popViewController(animated: false)

        // Then: 동기화 확인
        let vcCount = flow.navigationController.viewControllers.count
        let metadataCount = flow.currentStackMetadata.count
        #expect(vcCount == metadataCount)
        #expect(vcCount == 2)

        // metadata가 올바른 화면을 가리키는지 확인
        let metadata = flow.currentStackMetadata
        #expect(metadata[0].displayName == "A-1")
        #expect(metadata[1].displayName == "A-2")
    }

    @Test("NavigationFlow - 복잡한 시나리오에서 일관성 유지")
    func consistencyInComplexScenario() async throws {
        // Given
        let flow = TabAFlow()
        flow.animated = false

        // When: Push → Pop → Push → PopToRoot → Push 반복
        _ = flow.navigate(to: TabAStep.navigateToScreen1)
        _ = flow.navigate(to: TabAStep.navigateToScreen2)
        #expect(flow.navigationController.viewControllers.count == flow.currentStackMetadata.count)

        _ = flow.navigate(to: TabAStep.popViewController(count: 1))
        #expect(flow.navigationController.viewControllers.count == flow.currentStackMetadata.count)

        _ = flow.navigate(to: TabAStep.navigateToScreen3)
        _ = flow.navigate(to: TabAStep.navigateToScreen4)
        #expect(flow.navigationController.viewControllers.count == flow.currentStackMetadata.count)

        _ = flow.navigate(to: TabAStep.popToRoot)
        #expect(flow.navigationController.viewControllers.count == flow.currentStackMetadata.count)

        _ = flow.navigate(to: TabAStep.navigateToScreen5)
        #expect(flow.navigationController.viewControllers.count == flow.currentStackMetadata.count)

        // Then: 최종 일관성 확인
        let vcCount = flow.navigationController.viewControllers.count
        let metadataCount = flow.currentStackMetadata.count
        #expect(vcCount == metadataCount)
        #expect(vcCount == 2) // Root + Screen5
    }

    @Test("TabBarFlow - 탭 전환 후 각 탭의 스택 독립성")
    func stackIndependenceAcrossTabs() async throws {
        // Given
        let tabBarFlow = TabBarFlow()
        _ = tabBarFlow.navigate(to: AppStep.appDidStart)

        // Tab A에 화면 추가
        _ = tabBarFlow.navigate(to: TabAStep.navigateToScreen1)
        _ = tabBarFlow.navigate(to: TabAStep.navigateToScreen2)

        let tabANav = tabBarFlow.tabBarController.viewControllers?[0] as? UINavigationController
        let tabACount = tabANav?.viewControllers.count

        // When: Tab B로 전환 후 화면 추가
        _ = tabBarFlow.navigate(to: AppStep.switchToTabBScreen1)
        _ = tabBarFlow.navigate(to: TabBStep.navigateToScreen2)
        _ = tabBarFlow.navigate(to: TabBStep.navigateToScreen3)

        let tabBNav = tabBarFlow.tabBarController.viewControllers?[1] as? UINavigationController
        let tabBCount = tabBNav?.viewControllers.count

        // Then: Tab A의 스택은 영향받지 않아야 함 (root로 초기화됨)
        #expect(tabACount == 2) // 초기 상태
        #expect(tabANav?.viewControllers.count == 1) // 크로스 탭 시 root로 초기화
        #expect(tabBCount == 3) // Tab B는 3개
    }
}
