//
//  B_4ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class B_4ViewController: UIViewController {
    private let viewModel: B_4ViewModel
    private let commonView = CommonScreenView()

    init(viewModel: B_4ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = commonView
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupView()
        setupNavigationButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStackPath()
    }

    private func setupView() {
        commonView.configure(
            title: "B-4",
            icon: "🅱️",
            depth: viewModel.depth,
            color: .systemGreen
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "B-4",
            icon: "🅱️",
            depth: viewModel.depth,
            color: .systemGreen,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Next
        commonView.addNavigationButton(title: "➡️ Next (B-5)") { [weak self] in
            self?.viewModel.steps.send(TabBStep.navigateToScreen5)
        }

        // Back variations
        commonView.addNavigationButton(title: "⬅️ Back 1", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.popViewController())
        }

        commonView.addNavigationButton(title: "⬅️ Back 3", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.popViewController(count: 3))
        }

        // Modal
        commonView.addNavigationButton(title: "📱 Present Modal", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(ModalStep.presentModal)
        }
    }
}
