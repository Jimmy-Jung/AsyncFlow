//
//  LoginViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class LoginViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case emailChanged(String)
        case passwordChanged(String)
        case loginTapped
        case registerTapped
        case forgotPasswordTapped
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case updateEmail(String)
        case updatePassword(String)
        case startLogin
        case loginSuccess(User)
        case loginFailed(String)
        case navigateToRegister
        case navigateToForgotPassword
    }

    struct State: Equatable, Sendable {
        var email: String = ""
        var password: String = ""
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum CancelID: Hashable, Sendable {
        case login
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
        case let .emailChanged(email):
            return [.updateEmail(email)]
        case let .passwordChanged(password):
            return [.updatePassword(password)]
        case .loginTapped:
            return [.startLogin]
        case .registerTapped:
            return [.navigateToRegister]
        case .forgotPasswordTapped:
            return [.navigateToForgotPassword]
        case .cleanup:
            return []
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .updateEmail(email):
            state.email = email
            state.errorMessage = nil
            return [.none]

        case let .updatePassword(password):
            state.password = password
            state.errorMessage = nil
            return [.none]

        case .startLogin:
            state.isLoading = true
            state.errorMessage = nil
            return [
                .runCatchingError(
                    id: .login,
                    errorAction: { .loginFailed($0.localizedDescription) }
                ) { [authService, email = state.email, password = state.password] in
                    let user = try await authService.login(email: email, password: password)
                    return .loginSuccess(user)
                },
            ]

        case .loginSuccess:
            state.isLoading = false
            steps.send(AppStep.auth(.loginSuccess)) // ← AppFlow가 자동으로 받음!
            return [.none]

        case let .loginFailed(message):
            state.isLoading = false
            state.errorMessage = message
            return [.none]

        case .navigateToRegister:
            steps.send(AppStep.auth(.registerRequired))
            return [.none]

        case .navigateToForgotPassword:
            steps.send(AppStep.auth(.forgotPassword))
            return [.none]
        }
    }
}
