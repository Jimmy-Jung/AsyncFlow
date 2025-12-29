//
//  MainFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import SwiftUI
import UIKit

@MainActor
final class MainFlow: Flow {
    var root: any Presentable { tabBarController }
    private let tabBarController = UITabBarController()
    private let services: AppServices
    private let coordinator: FlowCoordinator

    private var dashboardFlow: DashboardFlow?
    private var settingsFlow: SettingsFlow?

    init(services: AppServices, coordinator: FlowCoordinator) {
        self.services = services
        self.coordinator = coordinator
    }

    func navigate(to step: Step) -> FlowContributors {
        guard let appStep = step as? AppStep else { return .none }
        switch appStep {
        case .main:
            return navigateToMain()

        case .dashboard:
            tabBarController.selectedIndex = 0
            return .none

        case .settings:
            tabBarController.selectedIndex = 1
            return .none

        default:
            return .none
        }
    }

    private func navigateToMain() -> FlowContributors {
        // Dashboard Flow
        let dashboardFlow = DashboardFlow(services: services)
        if let dashboardVC = dashboardFlow.root.viewController {
            dashboardVC.tabBarItem = UITabBarItem(
                title: "Dashboard",
                image: UIImage(systemName: "chart.bar"),
                tag: 0
            )
        }

        // Settings Flow
        let settingsFlow = SettingsFlow(services: services)
        if let settingsVC = settingsFlow.root.viewController {
            settingsVC.tabBarItem = UITabBarItem(
                title: "Settings",
                image: UIImage(systemName: "gear"),
                tag: 1
            )
        }

        self.dashboardFlow = dashboardFlow
        self.settingsFlow = settingsFlow

        tabBarController.viewControllers = [
            dashboardFlow.root.viewController,
            settingsFlow.root.viewController,
        ].compactMap { $0 }

        // 여러 자식 Flow를 FlowContributor로 반환 (자동으로 자식 FlowCoordinator 생성)
        return .multiple(flowContributors: [
            .contribute(
                withNextPresentable: dashboardFlow,
                withNextStepper: OneStepper(withSingleStep: AppStep.dashboard(.home))
            ),
            .contribute(
                withNextPresentable: settingsFlow,
                withNextStepper: OneStepper(withSingleStep: AppStep.settings(.settings))
            ),
        ])
    }
}
