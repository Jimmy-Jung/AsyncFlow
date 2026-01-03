//
//  AppFlow.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

/// 앱 전체 Flow 관리
@MainActor
final class AppFlow: Flow {
    // MARK: - Properties

    var root: Presentable { rootWindow }

    private let rootWindow: UIWindow
    private let tabBarFlow: TabBarFlow

    // MARK: - Initialization

    init(window: UIWindow) {
        rootWindow = window
        tabBarFlow = TabBarFlow()
    }

    // MARK: - Navigation

    func navigate(to step: Step) -> FlowContributors {
        // AppStep: 앱 레벨 네비게이션
        if let appStep = step as? AppStep {
            return handleAppStep(appStep)
        }

        // TabAStep, TabBStep: TabBarFlow로 전달
        if step is TabAStep || step is TabBStep {
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }

        // ModalStep: Modal 관리
        if let modalStep = step as? ModalStep {
            return handleModalStep(modalStep)
        }

        return .none
    }

    // MARK: - App Step Handling

    private func handleAppStep(_ step: AppStep) -> FlowContributors {
        switch step {
        case .appDidStart:
            return startApp()
        default:
            // 크로스 탭 네비게이션은 TabBarFlow로 전달
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }
    }

    private func startApp() -> FlowContributors {
        rootWindow.rootViewController = tabBarFlow.tabBarController
        rootWindow.makeKeyAndVisible()

        return .one(flowContributor: .contribute(
            withNextPresentable: tabBarFlow,
            withNextStepper: OneStepper(withSingleStep: AppStep.appDidStart)
        ))
    }

    // MARK: - Modal Step Handling

    private func handleModalStep(_ step: ModalStep) -> FlowContributors {
        switch step {
        case .presentModal:
            let modalFlow = ModalFlow()

            // 현재 보이는 ViewController에서 present
            if let presentingVC = getCurrentViewController() {
                if let presentable = modalFlow.root as? UIViewController {
                    presentingVC.present(presentable, animated: true)
                }
            }

            return .one(flowContributor: .contribute(
                withNextPresentable: modalFlow,
                withNextStepper: OneStepper(withSingleStep: ModalStep.presentModal)
            ))

        case .dismissModal:
            return .none
        }
    }

    // MARK: - Helper

    private func getCurrentViewController() -> UIViewController? {
        guard let tabBarController = rootWindow.rootViewController as? UITabBarController,
              let navigationController = tabBarController.selectedViewController as? UINavigationController
        else {
            return nil
        }
        return navigationController.topViewController
    }
}
