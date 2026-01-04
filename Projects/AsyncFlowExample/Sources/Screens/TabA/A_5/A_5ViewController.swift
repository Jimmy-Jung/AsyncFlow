//
//  A_5ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class A_5ViewController: UIViewController {
    private let viewModel: A_5ViewModel
    private let commonView = CommonScreenView()

    init(viewModel: A_5ViewModel) {
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
            title: "A-5",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "A-5",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Back variations
        commonView.addNavigationButton(title: "⬅️ Back 1", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popViewController())
        }

        commonView.addNavigationButton(title: "⬅️ Back 2", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popViewController(count: 2))
        }

        commonView.addNavigationButton(title: "⬅️ Back 3", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popViewController(count: 3))
        }

        // Root
        commonView.addNavigationButton(title: "🏠 Go to Root", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popToRoot)
        }

        // Cross Tab
        commonView.addNavigationButton(title: "🔄 Go to B-5", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(AppStep.switchToTabBScreen5)
        }
    }
}
