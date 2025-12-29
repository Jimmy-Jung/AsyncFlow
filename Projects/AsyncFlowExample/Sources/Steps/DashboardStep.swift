//
//  DashboardStep.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import Foundation

extension AppStep {
    enum Dashboard: Step {
        case home
        case featureList
        case featureDetail(Feature)
        case permissionRequired(message: String, permission: PermissionService.Permission)
        case back
        case dismiss
    }
}
