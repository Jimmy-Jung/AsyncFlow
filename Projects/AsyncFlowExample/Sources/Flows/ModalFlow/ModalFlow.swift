//
//  ModalFlow.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

/// Modal 관리 Flow
@MainActor
final class ModalFlow: Flow {
    // MARK: - Properties

    var root: Presentable { modalViewController }

    private let modalViewController: UIViewController
    private let viewModel: ModalViewModel

    // MARK: - Initialization

    init() {
        viewModel = ModalViewModel()
        modalViewController = ModalViewController(viewModel: viewModel)
    }

    // MARK: - Navigation

    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? ModalStep else { return .none }

        switch step {
        case .presentModal:
            // 이미 present된 상태
            return .one(flowContributor: .contribute(
                withNextPresentable: modalViewController,
                withNextStepper: viewModel
            ))

        case .dismissModal:
            modalViewController.dismiss(animated: true)
            return .none
        }
    }
}
