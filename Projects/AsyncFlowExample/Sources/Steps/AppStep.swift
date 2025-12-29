//
//  AppStep.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import Foundation

enum AppStep: Step {
    // MARK: - App Level

    case launch
    case onboarding
    case main
    case deepLink(URL)

    // MARK: - Nested Steps

    case auth(Auth)
    case dashboard(Dashboard)
    case settings(Settings)
}
