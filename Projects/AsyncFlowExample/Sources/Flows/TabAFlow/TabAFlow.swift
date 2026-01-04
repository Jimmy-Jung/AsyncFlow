//
//  TabAFlow.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

/// Tab A 네비게이션 Flow
@MainActor
final class TabAFlow: NavigationFlow {
    /// 테스트 환경에서는 애니메이션을 비활성화
    var animated: Bool = true

    // MARK: - Navigation

    override func navigate(to step: Step) -> FlowContributors {
        // AppStep, ModalStep은 상위 Flow로 전달
        if step is AppStep || step is ModalStep {
            return .one(flowContributor: .forwardToParentFlow(withStep: step))
        }

        guard let step = step as? TabAStep else { return .none }

        switch step {
        case .navigateToScreen1:
            return navigateToScreen1()
        case .navigateToScreen2:
            return navigateToScreen2()
        case .navigateToScreen3:
            return navigateToScreen3()
        case .navigateToScreen4:
            return navigateToScreen4()
        case .navigateToScreen5:
            return navigateToScreen5()
        case let .popViewController(count):
            return popViewController(count: count)
        case .popToRoot:
            return popToRoot()
        }
    }

    // MARK: - Private Navigation Methods

    private func navigateToScreen1() -> FlowContributors {
        let depth = navigationController.viewControllers.count
        let viewModel = A_1ViewModel(depth: depth)
        let viewController = A_1ViewController(viewModel: viewModel)

        // Step, Stepper, ViewController 연결 (메타데이터 자동 추적)
        associate(step: TabAStep.navigateToScreen1, stepper: viewModel, with: viewController)

        navigationController.pushViewController(viewController, animated: animated)

        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }

    private func navigateToScreen2() -> FlowContributors {
        let depth = navigationController.viewControllers.count
        let viewModel = A_2ViewModel(depth: depth)
        let viewController = A_2ViewController(viewModel: viewModel)

        associate(step: TabAStep.navigateToScreen2, stepper: viewModel, with: viewController)
        navigationController.pushViewController(viewController, animated: animated)

        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }

    private func navigateToScreen3() -> FlowContributors {
        let depth = navigationController.viewControllers.count
        let viewModel = A_3ViewModel(depth: depth)
        let viewController = A_3ViewController(viewModel: viewModel)

        associate(step: TabAStep.navigateToScreen3, stepper: viewModel, with: viewController)
        navigationController.pushViewController(viewController, animated: animated)

        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }

    private func navigateToScreen4() -> FlowContributors {
        let depth = navigationController.viewControllers.count
        let viewModel = A_4ViewModel(depth: depth)
        let viewController = A_4ViewController(viewModel: viewModel)

        associate(step: TabAStep.navigateToScreen4, stepper: viewModel, with: viewController)
        navigationController.pushViewController(viewController, animated: animated)

        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }

    private func navigateToScreen5() -> FlowContributors {
        let depth = navigationController.viewControllers.count
        let viewModel = A_5ViewModel(depth: depth)
        let viewController = A_5ViewController(viewModel: viewModel)

        associate(step: TabAStep.navigateToScreen5, stepper: viewModel, with: viewController)
        navigationController.pushViewController(viewController, animated: animated)

        return .one(flowContributor: .contribute(
            withNextPresentable: viewController,
            withNextStepper: viewModel
        ))
    }

    private func popViewController(count: Int) -> FlowContributors {
        let currentCount = navigationController.viewControllers.count
        let targetIndex = max(0, currentCount - count - 1)

        if targetIndex < navigationController.viewControllers.count {
            let targetVC = navigationController.viewControllers[targetIndex]
            navigationController.popToViewController(targetVC, animated: animated)
        }

        return .none
    }

    private func popToRoot() -> FlowContributors {
        navigationController.popToRootViewController(animated: animated)
        return .none
    }
}
