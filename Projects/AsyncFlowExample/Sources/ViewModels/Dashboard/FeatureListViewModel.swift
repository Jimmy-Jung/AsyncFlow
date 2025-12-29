//
//  FeatureListViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class FeatureListViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case featureTapped(Feature)
        case back
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case loadFeatures
        case featuresLoaded([Feature])
        case navigateToDetail(Feature)
        case navigateBack
        case stopped
    }

    struct State: Equatable, Sendable {
        var features: [Feature] = []
        var isLoading: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case loadFeatures
    }

    // MARK: - Properties

    @Published var state = State()

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .onAppear:
            return [.loadFeatures]
        case let .featureTapped(feature):
            return [.navigateToDetail(feature)]
        case .back:
            return [.navigateBack]
        case .cleanup:
            return [.stopped]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadFeatures:
            state.isLoading = true
            return [
                .run(id: .loadFeatures) {
                    try await Task.sleep(nanoseconds: 300_000_000)
                    return .featuresLoaded(Feature.mockFeatures)
                },
            ]

        case let .featuresLoaded(features):
            state.isLoading = false
            state.features = features
            return [.none]

        case let .navigateToDetail(feature):
            steps.send(AppStep.dashboard(.featureDetail(feature)))
            return [.none]

        case .navigateBack:
            steps.send(AppStep.dashboard(.back))
            return [.none]

        case .stopped:
            return [.cancel(id: .loadFeatures)]
        }
    }
}
