//
//  A_2ViewController.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
import UIKit

final class A_2ViewController: UIViewController {
    private let viewModel: A_2ViewModel
    private let commonView = CommonScreenView()

    init(viewModel: A_2ViewModel) {
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
            title: "A-2",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue
        )
    }

    private func updateStackPath() {
        commonView.configure(
            title: "A-2",
            icon: "🅰️",
            depth: viewModel.depth,
            color: .systemBlue,
            stackPath: navigationStackPath
        )
    }

    private func setupNavigationButtons() {
        // Next
        commonView.addNavigationButton(title: "➡️ Next (A-3)") { [weak self] in
            self?.viewModel.steps.send(TabAStep.navigateToScreen3)
        }

        // Back
        commonView.addNavigationButton(title: "⬅️ Back", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popViewController())
        }

        // Root
        commonView.addNavigationButton(title: "🏠 Go to Root", style: .secondary) { [weak self] in
            self?.viewModel.steps.send(TabAStep.popToRoot)
        }
    }
}
