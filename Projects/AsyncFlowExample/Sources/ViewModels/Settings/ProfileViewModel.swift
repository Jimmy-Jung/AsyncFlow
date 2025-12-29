//
//  ProfileViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class ProfileViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case back
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case loadProfile
        case profileLoaded(User?)
        case navigateBack
    }

    struct State: Equatable, Sendable {
        var user: User?
        var isLoading: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case loadProfile
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
            return [.loadProfile]
        case .back, .cleanup:
            return [.navigateBack]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadProfile:
            state.isLoading = true
            return [
                .run(id: .loadProfile) { @MainActor [authService] in
                    try await Task.sleep(nanoseconds: 200_000_000)
                    return .profileLoaded(authService.currentUser)
                },
            ]

        case let .profileLoaded(user):
            state.isLoading = false
            state.user = user
            return [.none]

        case .navigateBack:
            steps.send(AppStep.settings(.back))
            return [.none]
        }
    }
}
