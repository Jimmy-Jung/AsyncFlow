//
//  SettingsFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import SwiftUI
import UIKit

@MainActor
final class SettingsFlow: Flow {
    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()
    private let services: AppServices

    init(services: AppServices) {
        self.services = services
    }

    func navigate(to step: Step) -> FlowContributors {
        print("📍 SettingsFlow.navigate called with step: \(step)")
        guard let appStep = step as? AppStep,
              case let .settings(settingsStep) = appStep
        else {
            print("⚠️ Step is not Settings step")
            return .none
        }
        print("✅ Processing SettingsStep: \(settingsStep)")

        switch settingsStep {
        case .settings:
            return navigateToSettings()

        case .profile:
            return navigateToProfile()

        case .notifications:
            return navigateToNotifications()

        case .about:
            return navigateToAbout()

        case .logout:
            // AppFlow에서 자동으로 처리됨!
            return .none

        case .back:
            navigationController.popViewController(animated: true)
            return .none
        }
    }

    private func navigateToSettings() -> FlowContributors {
        print("⚙️ SettingsFlow.navigateToSettings called")
        let viewModel = SettingsViewModel(authService: services.authService)
        let viewController = SettingsViewController(viewModel: viewModel)

        navigationController.setViewControllers([viewController], animated: false)
        print("✅ NavigationController set with SettingsView")

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToProfile() -> FlowContributors {
        let viewModel = ProfileViewModel(authService: services.authService)
        let view = ProfileView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Profile"

        navigationController.pushViewController(viewController, animated: true)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToNotifications() -> FlowContributors {
        let viewModel = NotificationsViewModel()
        let viewController = NotificationsViewController(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToAbout() -> FlowContributors {
        let viewModel = AboutViewModel()
        let view = AboutView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "About"

        navigationController.pushViewController(viewController, animated: true)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }
}
