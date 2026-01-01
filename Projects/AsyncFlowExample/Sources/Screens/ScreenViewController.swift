import AsyncFlow
import Combine
import UIKit

/// 재사용 가능한 화면 ViewController
final class ScreenViewController: UIViewController {
    // MARK: - Properties

    let viewModel: ScreenViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()

    // MARK: - UI Components

    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let stackInfoLabel = UILabel()

    // Basic Navigation
    private let nextButton = UIButton(type: .system)

    // Back Navigation
    private let backButton = UIButton(type: .system)
    private let back2Button = UIButton(type: .system)
    private let back3Button = UIButton(type: .system)

    // Jump to Screen
    private let jumpStackView = UIStackView()

    // Go to Root
    private let goToRootButton = UIButton(type: .system)

    // DeepLink
    private let deepLinkButton = UIButton(type: .system)

    // MARK: - Initialization

    init(viewModel: ScreenViewModel) {
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.send(.viewDidAppear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.send(.viewDidDisappear)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupContentStackView()
        setupIconAndTitle()
        setupStackInfoLabel()
        setupBasicNavigation()
        setupBackNavigation()
        setupJumpToScreen()
        setupGoToRoot()
        setupDeepLink()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupContentStackView() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])
    }

    private func setupIconAndTitle() {
        let config = viewModel.state.config

        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 16
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let iconContainer = UIView()
        iconContainer.backgroundColor = config.color.withAlphaComponent(0.2)
        iconContainer.layer.cornerRadius = 30
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        iconLabel.text = config.emoji
        iconLabel.font = .systemFont(ofSize: 32)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconLabel)

        titleLabel.text = config.title
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        headerStack.addArrangedSubview(iconContainer)
        headerStack.addArrangedSubview(titleLabel)

        contentStackView.addArrangedSubview(headerStack)
        contentStackView.setCustomSpacing(10, after: headerStack)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
        ])
    }

    private func setupStackInfoLabel() {
        stackInfoLabel.font = .systemFont(ofSize: 14)
        stackInfoLabel.textColor = .secondaryLabel
        stackInfoLabel.textAlignment = .left
        stackInfoLabel.numberOfLines = 0
        stackInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(stackInfoLabel)
        contentStackView.setCustomSpacing(30, after: stackInfoLabel)
    }

    private func setupBasicNavigation() {
        let section = createSection(title: "📱 Basic Navigation")

        configureButton(
            nextButton,
            title: "➡️  Go to Next Screen",
            action: #selector(nextTapped)
        )
        section.addArrangedSubview(nextButton)
        contentStackView.addArrangedSubview(section)
    }

    private func setupBackNavigation() {
        let section = createSection(title: "🔄 Back Navigation")
        let buttonStack = createHorizontalButtonStack()

        configureButton(
            backButton,
            title: "⬅️  Back",
            action: #selector(backTapped)
        )
        buttonStack.addArrangedSubview(backButton)

        configureButton(
            back2Button,
            title: "⬅️⬅️ x2",
            action: #selector(back2Tapped)
        )
        buttonStack.addArrangedSubview(back2Button)

        configureButton(
            back3Button,
            title: "⬅️⬅️⬅️ x3",
            action: #selector(back3Tapped)
        )
        buttonStack.addArrangedSubview(back3Button)

        section.addArrangedSubview(buttonStack)
        contentStackView.addArrangedSubview(section)
    }

    private func setupJumpToScreen() {
        let section = createSection(title: "🎯 Jump to Screen")
        jumpStackView.axis = .horizontal
        jumpStackView.spacing = 10
        jumpStackView.distribution = .fillEqually
        jumpStackView.translatesAutoresizingMaskIntoConstraints = false

        for screen in DemoStep.Screen.allCases {
            let button = UIButton(type: .system)
            configureButton(
                button,
                title: screen.rawValue.uppercased(),
                action: #selector(jumpToScreenTapped(_:))
            )
            button.tag = screen.hashValue
            jumpStackView.addArrangedSubview(button)
        }
        section.addArrangedSubview(jumpStackView)
        contentStackView.addArrangedSubview(section)
    }

    private func setupGoToRoot() {
        let section = createSection(title: "🏠 Go to Root")
        configureButton(
            goToRootButton,
            title: "🏠 Go to Root (A)",
            action: #selector(goToRootTapped)
        )
        section.addArrangedSubview(goToRootButton)
        contentStackView.addArrangedSubview(section)
    }

    private func setupDeepLink() {
        let section = createSection(title: "🔗 DeepLink Simulation")
        configureButton(
            deepLinkButton,
            title: "🔗 Simulate DeepLink to Random Screen",
            action: #selector(deepLinkTapped)
        )
        section.addArrangedSubview(deepLinkButton)
        contentStackView.addArrangedSubview(section)
    }

    // MARK: - Helper UI Functions

    private func createSection(title: String) -> UIStackView {
        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 10
        sectionStack.alignment = .fill
        sectionStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionStack.addArrangedSubview(titleLabel)

        return sectionStack
    }

    private func createHorizontalButtonStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    // MARK: - Button Actions

    @objc private func nextTapped() {
        viewModel.send(.nextButtonTapped)
    }

    @objc private func backTapped() {
        viewModel.send(.backButtonTapped(1))
    }

    @objc private func back2Tapped() {
        viewModel.send(.backButtonTapped(2))
    }

    @objc private func back3Tapped() {
        viewModel.send(.backButtonTapped(3))
    }

    @objc private func jumpToScreenTapped(_ sender: UIButton) {
        if let screen = DemoStep.Screen.allCases.first(where: { $0.hashValue == sender.tag }) {
            viewModel.send(.jumpToScreenButtonTapped(screen))
        }
    }

    @objc private func goToRootTapped() {
        viewModel.send(.goToRootButtonTapped)
    }

    @objc private func deepLinkTapped() {
        if let randomScreen = DemoStep.Screen.allCases.filter({ $0 != viewModel.state.config.screen }).randomElement() {
            viewModel.send(.deepLinkButtonTapped(randomScreen))
        }
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        viewModel.$state
            .sink { [weak self] state in
                self?.updateUI(with: state)
            }
            .store(in: &cancellables)
    }

    private func updateUI(with state: ScreenViewModel.State) {
        title = state.config.title
        iconLabel.text = state.config.emoji
        titleLabel.text = state.config.title
        stackInfoLabel.text = state.stackInfo

        nextButton.isEnabled = state.nextScreen != nil
        nextButton.alpha = state.nextScreen != nil ? 1.0 : 0.5

        backButton.isEnabled = state.canGoBack
        backButton.alpha = state.canGoBack ? 1.0 : 0.5

        back2Button.isEnabled = state.canGoBack2
        back2Button.alpha = state.canGoBack2 ? 1.0 : 0.5

        back3Button.isEnabled = state.canGoBack3
        back3Button.alpha = state.canGoBack3 ? 1.0 : 0.5

        goToRootButton.isEnabled = state.canGoToRoot
        goToRootButton.alpha = state.canGoToRoot ? 1.0 : 0.5

        // Jump to Screen 버튼 활성화/비활성화
        for view in jumpStackView.arrangedSubviews {
            if let button = view as? UIButton {
                let isCurrentScreen = DemoStep.Screen.allCases.first(where: { $0.hashValue == button.tag }) == state.config.screen
                button.isEnabled = !isCurrentScreen
                button.alpha = isCurrentScreen ? 0.5 : 1.0
            }
        }
    }
}
