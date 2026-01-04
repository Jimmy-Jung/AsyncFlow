//
//  B_5ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class B_5ViewController: UIViewController {
    private let viewModel: B_5ViewModel
    private let commonView = CommonScreenView()

    init(viewModel: B_5ViewModel) {
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
            title: "B-5",
            icon: "🅱️",
            depth: viewModel.depth,
            color: .systemGreen
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "B-5",
            icon: "🅱️",
            depth: viewModel.depth,
            color: .systemGreen,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Back variations
        commonView.addNavigationButton(title: "⬅️ Back 1", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.popViewController())
        }

        commonView.addNavigationButton(title: "⬅️ Back 2", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.popViewController(count: 2))
        }

        commonView.addNavigationButton(title: "⬅️ Back 4", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.popViewController(count: 4))
        }

        // Root
        commonView.addNavigationButton(title: "🏠 Go to Root", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.popToRoot)
        }

        // Cross Tab
        commonView.addNavigationButton(title: "🔄 Go to A-3", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(AppStep.switchToTabAScreen3)
        }
    }
}
