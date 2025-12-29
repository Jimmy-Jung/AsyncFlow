//
//  SettingsViewController.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncViewModel
import Combine
import UIKit

final class SettingsViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization

    init(viewModel: SettingsViewModel) {
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

        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        viewModel.send(.onAppear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.send(.cleanup)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 3
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return viewModel.state.user != nil ? 1 : 0
        case 1: return 3
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryType = .disclosureIndicator

        var config = cell.defaultContentConfiguration()

        switch indexPath.section {
        case 0:
            if let user = viewModel.state.user {
                config.text = user.name
                config.secondaryText = user.email
                config.image = UIImage(systemName: "person.circle.fill")
            }

        case 1:
            switch indexPath.row {
            case 0:
                config.text = "Profile"
                config.image = UIImage(systemName: "person.fill")
            case 1:
                config.text = "Notifications"
                config.image = UIImage(systemName: "bell.fill")
            case 2:
                config.text = "About"
                config.image = UIImage(systemName: "info.circle.fill")
            default:
                break
            }

        case 2:
            config.text = "Logout"
            config.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
            cell.accessoryType = .none
            config.textProperties.color = .systemRed

        default:
            break
        }

        cell.contentConfiguration = config
        return cell
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Settings"
        default: return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                viewModel.send(.profileTapped)
            case 1:
                viewModel.send(.notificationsTapped)
            case 2:
                viewModel.send(.aboutTapped)
            default:
                break
            }

        case 2:
            showLogoutAlert()

        default:
            break
        }
    }

    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.viewModel.send(.logoutTapped)
        })

        present(alert, animated: true)
    }
}
