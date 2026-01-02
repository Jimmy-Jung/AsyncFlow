//
//  MainFlow.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 1.
//

import AsyncFlow
import UIKit

/// 메인 네비게이션 Flow
@MainActor
final class MainFlow: Flow {
    // MARK: - Properties

    var root: any Presentable {
        navigationController
    }

    private let navigationController = UINavigationController()

    // MARK: - Initialization

    init() {
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Flow Protocol

    func navigate(to step: Step) -> FlowContributors {
        guard let demoStep = step as? DemoStep else { return .none }

        switch demoStep {
        case .screenA:
            return navigateToScreen(.a, depth: 0)
        case .screenB:
            return navigateToScreen(.b, depth: currentDepth() + 1)
        case .screenC:
            return navigateToScreen(.c, depth: currentDepth() + 1)
        case .screenD:
            return navigateToScreen(.d, depth: currentDepth() + 1)
        case .screenE:
            return navigateToScreen(.e, depth: currentDepth() + 1)
        case .goBack:
            return goBack()
        case .goBack2:
            return goBack(count: 2)
        case .goBack3:
            return goBack(count: 3)
        case .goToRoot:
            return goToRoot()
        case let .goToSpecific(screen):
            return goToSpecific(screen: screen)
        case let .deepLink(screen):
            return deepLink(to: screen)
        }
    }

    // MARK: - Navigation Methods

    private func navigateToScreen(_ screen: DemoStep.Screen, depth: Int) -> FlowContributors {
        let viewModel = ScreenViewModel(screen: screen, depth: depth)
        let viewController = ScreenViewController(viewModel: viewModel)

        // Push
        navigationController.pushViewController(viewController, animated: true)

        return .one(
            flowContributor: .contribute(
                withNextPresentable: viewController,
                withNextStepper: viewModel
            )
        )
    }

    private func goBack(count: Int = 1) -> FlowContributors {
        guard navigationController.viewControllers.count > count else {
            return .none
        }

        let targetIndex = navigationController.viewControllers.count - count - 1
        let targetVC = navigationController.viewControllers[targetIndex]
        navigationController.popToViewController(targetVC, animated: true)

        return .none
    }

    private func goToRoot() -> FlowContributors {
        navigationController.popToRootViewController(animated: true)
        return .none
    }

    private func goToSpecific(screen: DemoStep.Screen) -> FlowContributors {
        // 이미 스택에 있는지 확인
        if let existingVC = findViewController(for: screen) {
            navigationController.popToViewController(existingVC, animated: true)
            return .none
        }

        // 없으면 새로 push
        let depth = currentDepth() + 1
        return navigateToScreen(screen, depth: depth)
    }

    private func deepLink(to screen: DemoStep.Screen) -> FlowContributors {
        // Root로 돌아간 후 해당 화면으로 이동
        navigationController.popToRootViewController(animated: false)

        // A → 목표 화면까지 순차 push
        let path = pathToScreen(screen)

        // 빈 경로면 이미 root(A)에 있으므로 .none 반환
        if path.isEmpty {
            return .none
        }

        for (index, targetScreen) in path.enumerated() {
            let viewModel = ScreenViewModel(screen: targetScreen, depth: index + 1)
            let viewController = ScreenViewController(viewModel: viewModel)
            navigationController.pushViewController(
                viewController,
                animated: index == path.count - 1
            )
        }

        // 마지막 ViewModel을 contributor로 반환
        if let lastScreen = path.last,
           let lastVC = navigationController.viewControllers.last as? ScreenViewController
        {
            return .one(
                flowContributor: .contribute(
                    withNextPresentable: lastVC,
                    withNextStepper: lastVC.viewModel
                )
            )
        }

        return .none
    }

    // MARK: - Helper Methods

    private func currentDepth() -> Int {
        return navigationController.viewControllers.count - 1
    }

    private func findViewController(
        for screen: DemoStep.Screen
    ) -> UIViewController? {
        // 실제 네비게이션 스택에서 찾기 (캐시가 아닌 실제 스택 확인)
        return navigationController.viewControllers.first { viewController in
            guard let screenVC = viewController as? ScreenViewController else { return false }
            return screenVC.viewModel.state.config.screen == screen
        }
    }

    private func pathToScreen(_ target: DemoStep.Screen) -> [DemoStep.Screen] {
        let allScreens = DemoStep.Screen.allCases
        guard let targetIndex = allScreens.firstIndex(of: target) else { return [] }

        // A(index 0)는 이미 root이므로, target이 A면 빈 배열 반환
        if targetIndex == 0 {
            return []
        }

        // A부터 target까지의 경로 (A 제외, target 포함)
        return Array(allScreens[1 ... targetIndex])
    }
}
