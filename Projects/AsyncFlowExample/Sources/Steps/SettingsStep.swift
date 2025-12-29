//
//  SettingsStep.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import Foundation

extension AppStep {
    enum Settings: Step {
        case settings
        case profile
        case notifications
        case about
        case logout
        case back
    }
}
