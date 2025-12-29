//
//  AppServices.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

struct AppServices: Sendable {
    let authService: AuthService
    let permissionService: PermissionService
    let deepLinkService: DeepLinkService
    let analyticsService: AnalyticsService
}
