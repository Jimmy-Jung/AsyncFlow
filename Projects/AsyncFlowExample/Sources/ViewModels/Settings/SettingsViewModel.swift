//
//  SettingsViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class SettingsViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case profileTapped
        case notificationsTapped
        case aboutTapped
        case logoutTapped
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case loadUser
        case userLoaded(User?)
        case navigateToProfile
        case navigateToNotifications
        case navigateToAbout
        case navigateToLogout
    }

    struct State: Equatable, Sendable {
        var user: User?
        var isLoading: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case loadUser
    }

    // MARK: - Properties

    @Published var state = State()
    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .onAppear:
            return [.loadUser]
        case .profileTapped:
            return [.navigateToProfile]
        case .notificationsTapped:
            return [.navigateToNotifications]
        case .aboutTapped:
            return [.navigateToAbout]
        case .logoutTapped:
            return [.navigateToLogout]
        case .cleanup:
            return []
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadUser:
            state.isLoading = true
            return [
                .run(id: .loadUser) { @MainActor [authService] in
                    try await Task.sleep(nanoseconds: 100_000_000)
                    return .userLoaded(authService.currentUser)
                },
            ]

        case let .userLoaded(user):
            state.isLoading = false
            state.user = user
            return [.none]

        case .navigateToProfile:
            steps.send(AppStep.settings(.profile))
            return [.none]

        case .navigateToNotifications:
            steps.send(AppStep.settings(.notifications))
            return [.none]

        case .navigateToAbout:
            steps.send(AppStep.settings(.about))
            return [.none]

        case .navigateToLogout:
            steps.send(AppStep.settings(.logout))
            return [.none]
        }
    }
}
