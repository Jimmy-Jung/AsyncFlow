//
//  AuthFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import SwiftUI
import UIKit

@MainActor
final class AuthFlow: Flow {
    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()
    private let services: AppServices

    init(services: AppServices) {
        self.services = services
    }

    func navigate(to step: Step) -> FlowContributors {
        guard let appStep = step as? AppStep,
              case let .auth(authStep) = appStep else { return .none }

        switch authStep {
        case .loginRequired:
            return navigateToLogin()

        case .registerRequired:
            return navigateToRegister()

        case .forgotPassword:
            return navigateToForgotPassword()

        case .loginSuccess, .registerSuccess:
            // AuthFlow 종료 및 부모 Flow에 main step 전달
            return .end(forwardToParentFlowWithStep: AppStep.main)

        case .loginCancelled:
            navigationController.dismiss(animated: true)
            return .none
        }
    }

    private func navigateToLogin() -> FlowContributors {
        let viewModel = LoginViewModel(authService: services.authService)
        let view = LoginView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = "Login"

        navigationController.setViewControllers([viewController], animated: false)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToRegister() -> FlowContributors {
        let viewModel = RegisterViewModel(authService: services.authService)
        let viewController = RegisterViewController(viewModel: viewModel)
        viewController.title = "Register"

        navigationController.pushViewController(viewController, animated: true)

        return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewModel))
    }

    private func navigateToForgotPassword() -> FlowContributors {
        let alert = UIAlertController(
            title: "비밀번호 찾기",
            message: "이메일을 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "email@example.com"
            textField.keyboardType = .emailAddress
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "전송", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text else { return }
            self?.services.analyticsService.trackAction("forgot_password", properties: ["email": email])
        })

        navigationController.present(alert, animated: true)

        return .none
    }
}
