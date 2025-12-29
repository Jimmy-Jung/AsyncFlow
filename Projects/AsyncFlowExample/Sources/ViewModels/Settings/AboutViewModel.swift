//
//  AboutViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class AboutViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case back
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case loadInfo
        case infoLoaded
        case navigateBack
    }

    struct State: Equatable, Sendable {
        var appName: String = "AsyncFlowExample"
        var version: String = "1.0.0"
        var build: String = "1"
        var isLoading: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case loadInfo
    }

    // MARK: - Properties

    @Published var state = State()

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .onAppear:
            return [.loadInfo]
        case .back, .cleanup:
            return [.navigateBack]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadInfo:
            state.isLoading = true
            return [
                .run(id: .loadInfo) {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    return .infoLoaded
                },
            ]

        case .infoLoaded:
            state.isLoading = false
            return [.none]

        case .navigateBack:
            steps.send(AppStep.settings(.back))
            return [.none]
        }
    }
}
