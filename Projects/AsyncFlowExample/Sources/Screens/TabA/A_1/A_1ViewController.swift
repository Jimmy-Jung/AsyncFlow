//
//  A_1ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class A_1ViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: A_1ViewModel
    private let commonView = CommonScreenView()

    // MARK: - Initialization

    init(viewModel: A_1ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

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

    // MARK: - Setup

    private func setupView() {
        commonView.configure(
            title: "A-1",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "A-1",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Next
        commonView.addNavigationButton(title: "➡️ Next (A-2)") { [weak self] in
            self?.viewModel.steps.send(TabAStep.navigateToScreen2)
        }

        // Jump
        commonView.addNavigationButton(title: "🎯 Jump to A-3", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.navigateToScreen3)
        }

        commonView.addNavigationButton(title: "🎯 Jump to A-5", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.navigateToScreen5)
        }

        // Cross Tab
        commonView.addNavigationButton(title: "🔄 Go to B-3", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(AppStep.switchToTabBScreen3)
        }

        // Modal
        commonView.addNavigationButton(title: "📱 Present Modal", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(ModalStep.presentModal)
        }
    }
}
