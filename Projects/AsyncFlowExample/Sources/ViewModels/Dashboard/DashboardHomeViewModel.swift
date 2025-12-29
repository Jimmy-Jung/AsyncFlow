//
//  DashboardHomeViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Foundation

@AsyncViewModel
final class DashboardHomeViewModel: ObservableObject, Stepper {
    // MARK: - Stepper

    @Steps var steps

    // MARK: - Types

    enum Input: Equatable, Sendable {
        case onAppear
        case featureListTapped
        case permissionFeatureTapped
        case reloadFeatures
        case cleanup
    }

    enum Action: Equatable, Sendable {
        case loadFeatures
        case featuresLoaded([Feature], grantedPermissions: [String: Bool])
        case navigateToFeatureList
        case navigateToPermissionRequired
        case stopped
    }

    struct State: Equatable, Sendable {
        var features: [Feature] = []
        var isLoading: Bool = false
        var grantedPermissions: [String: Bool] = [:] // Feature 이름을 키로 사용
    }

    enum CancelID: Hashable, Sendable {
        case loadFeatures
    }

    // MARK: - Properties

    @Published var state = State()
    private let permissionService: PermissionService

    init(permissionService: PermissionService) {
        self.permissionService = permissionService
    }

    // MARK: - Transform

    func transform(_ input: Input) -> [Action] {
        switch input {
        case .onAppear:
            return [.loadFeatures]
        case .featureListTapped:
            return [.navigateToFeatureList]
        case .permissionFeatureTapped:
            return [.navigateToPermissionRequired]
        case .reloadFeatures:
            return [.loadFeatures]
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
                .run(id: .loadFeatures) { [permissionService] in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let features = Feature.mockFeatures

                    // 각 Feature에 대한 권한 상태 체크 (Feature 이름을 키로 사용)
                    var grantedPermissions: [String: Bool] = [:]
                    for feature in features where feature.requiresPermission {
                        let permission = await Self.permissionForFeature(feature)
                        let granted = await permissionService.checkPermission(permission)
                        grantedPermissions[feature.name] = granted
                    }

                    return .featuresLoaded(features, grantedPermissions: grantedPermissions)
                },
            ]

        case let .featuresLoaded(features, grantedPermissions):
            state.isLoading = false
            state.features = features
            state.grantedPermissions = grantedPermissions
            return [.none]

        case .navigateToFeatureList:
            steps.send(AppStep.dashboard(.featureList))
            return [.none]

        case .navigateToPermissionRequired:
            steps.send(AppStep.dashboard(.permissionRequired(
                message: "카메라 권한이 필요합니다",
                permission: .camera
            )))
            return [.none]

        case .stopped:
            return [.cancel(id: .loadFeatures)]
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
            return .camera // 기본값
        }
    }
}
