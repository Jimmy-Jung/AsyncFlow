//
//  TabBarFlow.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

/// TabBar 관리 Flow
@MainActor
final class TabBarFlow: Flow {
    // MARK: - Properties

    var root: Presentable { tabBarController }

    let tabBarController = UITabBarController()
    private let tabAFlow: TabAFlow
    private let tabBFlow: TabBFlow

    // MARK: - Initialization

    init() {
        tabAFlow = TabAFlow()
        tabBFlow = TabBFlow()
        setupTabBar()
    }

    // MARK: - Setup

    private func setupTabBar() {
        let tabANavController = tabAFlow.navigationController
        tabANavController.tabBarItem = UITabBarItem(title: "Tab A", image: nil, tag: 0)

        let tabBNavController = tabBFlow.navigationController
        tabBNavController.tabBarItem = UITabBarItem(title: "Tab B", image: nil, tag: 1)

        tabBarController.viewControllers = [tabANavController, tabBNavController]
    }

    // MARK: - Navigation

    func navigate(to step: Step) -> FlowContributors {
        // AppStep: 크로스 탭 네비게이션
        if let appStep = step as? AppStep {
            return handleAppStep(appStep)
        }

        // ModalStep: 상위 Flow로 전달
        if step is ModalStep {
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }

        // TabAStep: Tab A Flow로 전달
        if step is TabAStep {
            return tabAFlow.navigate(to: step)
        }

        // TabBStep: Tab B Flow로 전달
        if step is TabBStep {
            return tabBFlow.navigate(to: step)
        }

        return .none
    }

    // MARK: - Cross-Tab Navigation

    private func handleAppStep(_ step: AppStep) -> FlowContributors {
        switch step {
        case .appDidStart:
            return startApp()

        case .switchToTabAScreen1:
            return switchToTab(index: 0, targetStep: TabAStep.navigateToScreen1)

        case .switchToTabAScreen2:
            return switchToTab(index: 0, targetStep: TabAStep.navigateToScreen2)

        case .switchToTabAScreen3:
            return switchToTab(index: 0, targetStep: TabAStep.navigateToScreen3)

        case .switchToTabAScreen5:
            return switchToTab(index: 0, targetStep: TabAStep.navigateToScreen5)

        case .switchToTabBScreen1:
            return switchToTab(index: 1, targetStep: TabBStep.navigateToScreen1)

        case .switchToTabBScreen3:
            return switchToTab(index: 1, targetStep: TabBStep.navigateToScreen3)

        case .switchToTabBScreen5:
            return switchToTab(index: 1, targetStep: TabBStep.navigateToScreen5)
        }
    }

    private func startApp() -> FlowContributors {
        // Tab A 시작 (A-1 화면)
        return .multiple(flowContributors: [
            .contribute(
                withNextPresentable: tabAFlow,
                withNextStepper: OneStepper(withSingleStep: TabAStep.navigateToScreen1)
            ),
            .contribute(
                withNextPresentable: tabBFlow,
                withNextStepper: OneStepper(withSingleStep: TabBStep.navigateToScreen1)
            ),
        ])
    }

    /// 탭 전환 + 특정 화면 이동
    ///
    /// 1. 현재 탭의 네비게이션 스택을 루트로 pop
    /// 2. 대상 탭으로 전환
    /// 3. 대상 화면으로 navigate
    private func switchToTab(index: Int, targetStep: Step) -> FlowContributors {
        // 1. 현재 탭 스택 정리
        if let currentNav = tabBarController.selectedViewController as? UINavigationController {
            currentNav.popToRootViewController(animated: false)
        }

        // 2. 탭 전환
        tabBarController.selectedIndex = index

        // 3. 대상 Flow로 네비게이션 요청 전달
        if index == 0 {
            return tabAFlow.navigate(to: targetStep)
        } else if index == 1 {
            return tabBFlow.navigate(to: targetStep)
        }

        return .none
    }
}
