//
//  AppFlow.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 1.
//

import AsyncFlow
import SwiftUI
import UIKit

/// 앱의 최상위 Flow
@MainActor
final class AppFlow: Flow {
    // MARK: - Properties

    var root: any Presentable {
        rootViewController
    }

    private let rootViewController: RootViewController
    private var mainFlow: MainFlow?

    // MARK: - Initialization

    init(window: UIWindow) {
        rootViewController = RootViewController(window: window)
    }

    // MARK: - Flow Protocol

    func navigate(to step: Step) -> FlowContributors {
        guard let demoStep = step as? DemoStep else { return .none }

        switch demoStep {
        case .screenA:
            return navigateToMain()
        default:
            // MainFlow에 위임
            return .one(flowContributor: .forwardToCurrentFlow(withStep: demoStep))
        }
    }

    // MARK: - Navigation Methods

    private func navigateToMain() -> FlowContributors {
        let mainFlow = MainFlow()
        self.mainFlow = mainFlow

        // RootViewController에 MainFlow의 root 설정
        guard let navigationController = mainFlow.root.viewController as? UINavigationController else {
            fatalError("MainFlow.root must be a UINavigationController")
        }
        rootViewController.setContent(navigationController)

        return .one(flowContributor: .contribute(
            withNextPresentable: mainFlow,
            withNextStepper: OneStepper(withSingleStep: DemoStep.screenA)
        ))
    }
}

/// 앱의 Root ViewController
///
/// NavigationStack (SwiftUI) + Content (UIKit)를 관리합니다.
final class RootViewController: UIViewController {
    // MARK: - Properties

    private let window: UIWindow
    private weak var mainNavController: UINavigationController?
    private var stackHostingController: UIHostingController<AnyView>?

    private let stackViewModel = NavigationStackViewModel.shared

    // MARK: - Initialization

    init(window: UIWindow) {
        self.window = window
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavigationStack()

        // Window 설정
        window.rootViewController = self
        window.makeKeyAndVisible()
    }

    // MARK: - Setup

    private func setupNavigationStack() {
        // NavigationStackView (SwiftUI)
        let stackView = NavigationStackView()
            .environmentObject(stackViewModel)
        let hostingController = UIHostingController(rootView: AnyView(stackView))
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: NavigationStackViewModel.fixedHeight),
        ])

        stackHostingController = hostingController
    }

    // MARK: - Public Methods

    func setContent(_ navigationController: UINavigationController) {
        // 기존 content 제거
        mainNavController?.willMove(toParent: nil)
        mainNavController?.view.removeFromSuperview()
        mainNavController?.removeFromParent()

        // 새 content 추가
        addChild(navigationController)
        view.addSubview(navigationController.view)

        navigationController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            navigationController.view.topAnchor.constraint(
                equalTo: stackHostingController?.view.bottomAnchor ?? view.topAnchor
            ),
            navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        navigationController.didMove(toParent: self)

        // Delegate 설정
        navigationController.delegate = self
        mainNavController = navigationController
    }
}

// MARK: - UINavigationControllerDelegate

extension RootViewController: UINavigationControllerDelegate {
    func navigationController(
        _: UINavigationController,
        willShow viewController: UIViewController,
        animated _: Bool
    ) {
        // 애니메이션 시작 직전에 호출 (즉각 반응)
        guard let screenVC = viewController as? ScreenViewController else { return }

        let screen = screenVC.viewModel.state.config.screen
        print("🔄 Navigation willShow: \(screen)")

        // NavigationStack 업데이트
        stackViewModel.updateCurrentScreen(screen)
    }
}
