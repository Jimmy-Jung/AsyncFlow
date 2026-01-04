//
//  A_4ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class A_4ViewController: UIViewController {
    private let viewModel: A_4ViewModel
    private let commonView = CommonScreenView()

    init(viewModel: A_4ViewModel) {
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
            title: "A-4",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "A-4",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Next
        commonView.addNavigationButton(title: "➡️ Next (A-5)") { [weak self] in
            self?.viewModel.steps.send(TabAStep.navigateToScreen5)
        }

        // Back variations
        commonView.addNavigationButton(title: "⬅️ Back 1", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popViewController())
        }

        commonView.addNavigationButton(title: "⬅️ Back 3", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popViewController(count: 3))
        }

        // Cross Tab
        commonView.addNavigationButton(title: "🔄 Go to B-1", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(AppStep.switchToTabBScreen1)
        }
    }
}
