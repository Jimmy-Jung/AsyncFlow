//
//  B_1ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class B_1ViewController: UIViewController {
    private let viewModel: B_1ViewModel
    private let commonView = CommonScreenView()

    init(viewModel: B_1ViewModel) {
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
            title: "B-1",
            icon: "🅱️",
            depth: viewModel.depth,
            color: .systemGreen
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "B-1",
            icon: "🅱️",
            depth: viewModel.depth,
            color: .systemGreen,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Next
        commonView.addNavigationButton(title: "➡️ Next (B-2)") { [weak self] in
            self?.viewModel.steps.send(TabBStep.navigateToScreen2)
        }

        // Jump
        commonView.addNavigationButton(title: "🎯 Jump to B-4", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabBStep.navigateToScreen4)
        }

        // Cross Tab
        commonView.addNavigationButton(title: "🔄 Go to A-2", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(AppStep.switchToTabAScreen2)
        }

        // Modal
        commonView.addNavigationButton(title: "📱 Present Modal", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(ModalStep.presentModal)
        }
    }
}
