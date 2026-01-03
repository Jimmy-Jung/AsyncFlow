//
//  CommonScreenView.swift
//  AsyncFlowExample
//
//  Created by jimmy on 2026. 1. 3.
//

import UIKit

/// 화면 공통 UI 컴포넌트
///
/// 모든 화면에서 공통적으로 사용하는 UI 요소를 제공합니다.
final class CommonScreenView: UIView {
    // MARK: - UI Components

    /// 헤더 컨테이너
    private let headerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 헤더 스택뷰
    private let headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 네비게이션 스택 표시 레이블
    private let stackLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 현재 화면 정보 컨테이너
    private let currentScreenContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 화면 아이콘 레이블
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 화면 정보 스택 (타이틀 + Depth)
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 화면 제목 레이블
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Depth 정보 레이블
    private let depthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 네비게이션 버튼 컨테이너
    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 스크롤 뷰
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    /// 콘텐츠 컨테이너
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground

        addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 헤더 구성
        contentView.addSubview(headerContainer)
        headerContainer.addSubview(headerStackView)

        // 스택 경로 라벨
        headerStackView.addArrangedSubview(stackLabel)

        // Depth 정보
        headerStackView.addArrangedSubview(depthLabel)

        // 버튼 스택
        contentView.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header Container
            headerContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Header Stack
            headerStackView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 20),
            headerStackView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            headerStackView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
            headerStackView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -20),

            // Button Stack
            buttonStackView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 32),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Configuration

    /// 화면 정보 설정
    func configure(
        title _: String,
        icon _: String,
        depth: Int,
        color: UIColor,
        stackPath: String? = nil
    ) {
        // Depth 정보 설정
        depthLabel.text = "Depth: \(depth)"

        // 네비게이션 스택 표시 (현재 화면 강조)
        if let stackPath = stackPath, !stackPath.isEmpty {
            let components = stackPath.components(separatedBy: " → ")

            let attributedText = NSMutableAttributedString()

            // 책 이모지
            attributedText.append(NSAttributedString(
                string: "📚 ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                ]
            ))

            if components.count > 1 {
                // 이전 경로들 (작게, 연하게)
                for (index, component) in components.enumerated() {
                    if index == components.count - 1 {
                        // 현재 화면 (크게, 볼드, 컬러)
                        attributedText.append(NSAttributedString(
                            string: component,
                            attributes: [
                                .foregroundColor: color,
                                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                            ]
                        ))
                    } else {
                        // 이전 화면들
                        attributedText.append(NSAttributedString(
                            string: component,
                            attributes: [
                                .foregroundColor: UIColor.tertiaryLabel,
                                .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                            ]
                        ))

                        // 화살표
                        attributedText.append(NSAttributedString(
                            string: " → ",
                            attributes: [
                                .foregroundColor: UIColor.quaternaryLabel,
                                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                            ]
                        ))
                    }
                }
            } else {
                // 첫 화면 (크게, 볼드, 컬러)
                attributedText.append(NSAttributedString(
                    string: stackPath,
                    attributes: [
                        .foregroundColor: color,
                        .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    ]
                ))
            }

            stackLabel.attributedText = attributedText
            stackLabel.isHidden = false
        } else {
            stackLabel.isHidden = true
        }

        // 배경색을 불투명하게 설정 (화면 겹침 방지)
        backgroundColor = .systemBackground
    }

    /// 네비게이션 버튼 추가
    func addNavigationButton(
        title: String,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        let button = NavigationButton(title: title, style: style, action: action)
        buttonStackView.addArrangedSubview(button)
    }

    /// 모든 버튼 제거
    func clearButtons() {
        buttonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - NavigationButton

private final class NavigationButton: UIButton {
    private let action: () -> Void

    init(title: String, style: ButtonStyle, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
        ])

        applyStyle(style)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyStyle(_ style: ButtonStyle) {
        switch style {
        case .primary:
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
        case .secondary:
            backgroundColor = .systemGray5
            setTitleColor(.label, for: .normal)
        case .destructive:
            backgroundColor = .systemRed
            setTitleColor(.white, for: .normal)
        }
    }

    @objc private func buttonTapped() {
        action()
    }
}

// MARK: - ButtonStyle

enum ButtonStyle {
    case primary
    case secondary
    case destructive
}
