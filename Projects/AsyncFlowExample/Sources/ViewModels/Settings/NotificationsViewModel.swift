//
//  NotificationsViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class NotificationsViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case toggleNotifications(Bool)
        case back
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case loadSettings
        case settingsLoaded
        case updateNotifications(Bool)
        case notificationsUpdated
        case navigateBack
    }

    struct State: Equatable, Sendable {
        var notificationsEnabled: Bool = false
        var isLoading: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case loadSettings
        case updateSettings
    }

    // MARK: - Properties

    @Published var state = State()

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .onAppear:
            return [.loadSettings]
        case let .toggleNotifications(enabled):
            return [.updateNotifications(enabled)]
        case .back, .cleanup:
            return [.navigateBack]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadSettings:
            state.isLoading = true
            return [
                .run(id: .loadSettings) {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    return .settingsLoaded
                },
            ]

        case .settingsLoaded:
            state.isLoading = false
            state.notificationsEnabled = true
            return [.none]

        case let .updateNotifications(enabled):
            state.notificationsEnabled = enabled
            return [
                .run(id: .updateSettings) {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    return .notificationsUpdated
                },
            ]

        case .notificationsUpdated:
            return [.none]

        case .navigateBack:
            steps.send(AppStep.settings(.back))
            return [.none]
        }
    }
}
