//
//  RegisterViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class RegisterViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case nameChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
        case registerTapped
        case cancelTapped
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case updateName(String)
        case updateEmail(String)
        case updatePassword(String)
        case startRegister
        case registerSuccess(User)
        case registerFailed(String)
        case navigateBack
    }

    struct State: Equatable, Sendable {
        var name: String = ""
        var email: String = ""
        var password: String = ""
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum CancelID: Hashable, Sendable {
        case register
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
        case let .nameChanged(name):
            return [.updateName(name)]
        case let .emailChanged(email):
            return [.updateEmail(email)]
        case let .passwordChanged(password):
            return [.updatePassword(password)]
        case .registerTapped:
            return [.startRegister]
        case .cancelTapped, .cleanup:
            return [.navigateBack]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case let .updateName(name):
            state.name = name
            state.errorMessage = nil
            return [.none]

        case let .updateEmail(email):
            state.email = email
            state.errorMessage = nil
            return [.none]

        case let .updatePassword(password):
            state.password = password
            state.errorMessage = nil
            return [.none]

        case .startRegister:
            state.isLoading = true
            state.errorMessage = nil
            return [
                .runCatchingError(
                    id: .register,
                    errorAction: { .registerFailed($0.localizedDescription) }
                ) { [authService, name = state.name, email = state.email, password = state.password] in
                    let user = try await authService.register(name: name, email: email, password: password)
                    return .registerSuccess(user)
                },
            ]

        case .registerSuccess:
            state.isLoading = false
            steps.send(AppStep.auth(.registerSuccess))
            return [.none]

        case let .registerFailed(message):
            state.isLoading = false
            state.errorMessage = message
            return [.none]

        case .navigateBack:
            steps.send(AppStep.auth(.loginCancelled))
            return [.none]
        }
    }
}
