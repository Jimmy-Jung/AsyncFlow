//
//  DashboardFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import SwiftUI
import UIKit

@MainActor
final class DashboardFlow: Flow {
    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()
    private let services: AppServices
    private weak var homeViewModel: DashboardHomeViewModel?

    init(services: AppServices) {
        self.services = services
    }

    // MARK: - Step Adaptation (권한 체크)

    func adapt(step: Step) async -> Step {
        // 권한 체크는 디테일 화면에서 처리하도록 변경
        return step
    }

    // MARK: - Navigation

    func navigate(to step: Step) -> FlowContributors {
        print("📍 DashboardFlow.navigate called with step: \(step)")
        guard let appStep = step as? AppStep,
              case let .dashboard(dashboardStep) = appStep
        else {
            print("⚠️ Step is not Dashboard step")
            return .none
        }
        print("✅ Processing DashboardStep: \(dashboardStep)")

        switch dashboardStep {
        case .home:
            return navigateToHome()

        case .featureList:
            return navigateToFeatureList()

        case let .featureDetail(feature):
            return navigateToFeatureDetail(feature)

        case let .permissionRequired(message, permission):
            return navigateToPermissionRequired(message, permission: permission)

        case .back:
            navigationController.popViewController(animated: true)
            return .none

        case .dismiss:
            navigationController.dismiss(animated: true)
            return .none
        }
    }

    // MARK: - Private

    private func navigateToHome() -> FlowContributors {
        print("🏠 DashboardFlow.navigateToHome called")
        let viewModel = DashboardHomeViewModel(permissionService: services.permissionService)
        homeViewModel = viewModel
        let view = DashboardHomeView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Dashboard"

        navigationController.setViewControllers([viewController], animated: false)
        print("✅ NavigationController set with DashboardHomeView")
        print("📊 NavigationController.viewControllers count: \(navigationController.viewControllers.count)")
        print("📊 ViewController: \(viewController)")
        print("📊 NavigationController.view.frame: \(navigationController.view.frame)")

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToFeatureList() -> FlowContributors {
        let viewModel = FeatureListViewModel()
        let view = FeatureListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Features"

        navigationController.pushViewController(viewController, animated: true)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToFeatureDetail(_ feature: Feature) -> FlowContributors {
        let viewModel = FeatureDetailViewModel(feature: feature, permissionService: services.permissionService)
        let viewController = FeatureDetailViewController(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToPermissionRequired(_ message: String, permission: PermissionService.Permission) -> FlowContributors {
        let view = PermissionRequiredView(
            message: message,
            onRequestPermission: { [weak self] in
                guard let self = self else { return }

                Task { @MainActor in
                    print("🔐 Requesting permission: \(permission)")
                    let granted = await self.services.permissionService.requestPermission(permission)
                    print("✅ Permission granted: \(granted)")

                    if granted {
                        // 권한이 부여되면 이전 화면(디테일 화면)으로 돌아감
                        // 디테일 화면의 viewWillAppear에서 권한 상태를 다시 체크함
                        self.navigationController.popViewController(animated: true)
                        // pop 후 약간의 딜레이를 두고 Home ViewModel에 Feature를 다시 로드하도록 알림
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        self.homeViewModel?.send(.reloadFeatures)
                    } else {
                        // 권한이 거부되면 사용자에게 알림 (선택사항)
                        let alert = UIAlertController(
                            title: "Permission Denied",
                            message: "권한이 거부되었습니다. 설정에서 권한을 허용해주세요.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.navigationController.present(alert, animated: true)
                    }
                }
            },
            onDismiss: { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }
        )
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Permission Required"

        navigationController.pushViewController(viewController, animated: true)

        return .none
    }
}
