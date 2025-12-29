//
//  FeatureDetailViewController.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import Combine
import UIKit

final class FeatureDetailViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: FeatureDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let permissionBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let permissionLabel: UILabel = {
        let label = UILabel()
        label.text = "🔒 Permission Required"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemOrange
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let requestPermissionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Request Permission", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Initialization

    init(viewModel: FeatureDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()

        title = "Feature Detail"
        view.backgroundColor = .systemBackground

        viewModel.send(.onAppear)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 권한 요청 화면에서 돌아왔을 때만 권한 상태를 다시 체크
        // navigationController의 viewControllers를 확인하여 권한 요청 화면이 제거되었는지 확인
        if viewModel.state.feature.requiresPermission, !viewModel.state.hasPermission {
            // 권한 요청 화면에서 돌아온 경우 권한을 다시 체크
            // 이전 화면으로 돌아왔다면 권한 요청 화면이 navigation stack에서 제거되었을 것
            viewModel.send(.recheckPermission)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 실제로 navigation stack에서 제거될 때만 cleanup 호출
        if isMovingFromParent {
            viewModel.send(.cleanup)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let iconContainer = UIView()
        iconContainer.addSubview(iconImageView)

        contentStack.addArrangedSubview(iconContainer)
        contentStack.addArrangedSubview(nameLabel)
        contentStack.addArrangedSubview(descriptionLabel)

        if viewModel.state.feature.requiresPermission {
            permissionBadge.addSubview(permissionLabel)
            contentStack.addArrangedSubview(permissionBadge)
            contentStack.addArrangedSubview(requestPermissionButton)

            requestPermissionButton.addTarget(self, action: #selector(requestPermissionTapped), for: .touchUpInside)

            NSLayoutConstraint.activate([
                permissionLabel.topAnchor.constraint(equalTo: permissionBadge.topAnchor, constant: 12),
                permissionLabel.leadingAnchor.constraint(equalTo: permissionBadge.leadingAnchor, constant: 16),
                permissionLabel.trailingAnchor.constraint(equalTo: permissionBadge.trailingAnchor, constant: -16),
                permissionLabel.bottomAnchor.constraint(equalTo: permissionBadge.bottomAnchor, constant: -12),

                requestPermissionButton.heightAnchor.constraint(equalToConstant: 50),
                requestPermissionButton.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
                requestPermissionButton.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
            ])
        }

        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 100),
            iconImageView.heightAnchor.constraint(equalToConstant: 100),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    private func render(_ state: FeatureDetailViewModel.State) {
        iconImageView.image = UIImage(systemName: state.feature.icon)
        nameLabel.text = state.feature.name
        descriptionLabel.text = state.feature.description

        if state.isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        // 권한 상태에 따라 UI 업데이트
        if state.feature.requiresPermission {
            permissionBadge.isHidden = state.hasPermission
            requestPermissionButton.isHidden = state.hasPermission

            if state.hasPermission {
                permissionLabel.text = "✅ Permission Granted"
                permissionLabel.textColor = .systemGreen
                permissionBadge.backgroundColor = .systemGreen.withAlphaComponent(0.1)
            } else {
                permissionLabel.text = "🔒 Permission Required"
                permissionLabel.textColor = .systemOrange
                permissionBadge.backgroundColor = .systemOrange.withAlphaComponent(0.1)
            }
        }
    }

    @objc private func requestPermissionTapped() {
        viewModel.send(.requestPermission)
    }
}
