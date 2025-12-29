//
//  FeatureDetailViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class FeatureDetailViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case back
        case cleanup
        case requestPermission
        case recheckPermission
    }

    enum Action: Equatable, Sendable {
        case loadDetails
        case detailsLoaded
        case checkPermission
        case permissionChecked(Bool)
        case navigateToPermissionRequired
        case navigateBack
        case stopped
    }

    struct State: Equatable, Sendable {
        var feature: Feature
        var isLoading: Bool = false
        var hasPermission: Bool = false
    }

    enum CancelID: Hashable, Sendable {
        case loadDetails
        case checkPermission
    }

    // MARK: - Properties

    @Published var state: State
    private let permissionService: PermissionService

    // MARK: - Initialization

    init(feature: Feature, permissionService: PermissionService) {
        state = State(feature: feature)
        self.permissionService = permissionService
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .onAppear:
            return [.loadDetails, .checkPermission]
        case .recheckPermission:
            return [.checkPermission]
        case .requestPermission:
            return [.navigateToPermissionRequired]
        case .back:
            return [.navigateBack]
        case .cleanup:
            return [.stopped]
        }
    }

    // MARK: - Reduce

    func reduce(state: inout State, action: Action) -> [AsyncEffect<Action, CancelID>] {
        switch action {
        case .loadDetails:
            state.isLoading = true
            return [
                .run(id: .loadDetails) {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    return .detailsLoaded
                },
            ]

        case .detailsLoaded:
            state.isLoading = false
            return [.none]

        case .checkPermission:
            guard state.feature.requiresPermission else {
                state.hasPermission = true
                return [.none]
            }
            let feature = state.feature
            let permission = Self.permissionForFeature(feature)
            return [
                .run(id: .checkPermission) { [permissionService] in
                    let hasPermission = await permissionService.checkPermission(permission)
                    return .permissionChecked(hasPermission)
                },
            ]

        case let .permissionChecked(hasPermission):
            state.hasPermission = hasPermission
            // 권한 상태만 업데이트하고, 권한 요청 화면으로 자동 이동하지 않음
            // 사용자가 "Request Permission" 버튼을 누를 때만 이동
            return [.none]

        case .navigateToPermissionRequired:
            let permission = Self.permissionForFeature(state.feature)
            steps.send(AppStep.dashboard(.permissionRequired(
                message: "\(state.feature.name) 기능을 사용하려면 권한이 필요합니다",
                permission: permission
            )))
            return [.none]

        case .navigateBack:
            steps.send(AppStep.dashboard(.back))
            return [.none]

        case .stopped:
            return [.cancel(id: .loadDetails), .cancel(id: .checkPermission)]
        }
    }

    // MARK: - Helpers

    private static func permissionForFeature(_ feature: Feature) -> PermissionService.Permission {
        switch feature.name {
        case "Camera Scanner":
            return .camera
        case "Location Tracker":
            return .location
        case "Photo Library":
            return .photoLibrary
        case "Contacts":
            return .contacts
        case "Push Notifications":
            return .notifications
        default:
            return .camera
        }
    }
}
