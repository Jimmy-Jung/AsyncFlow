//
//  AuthStep.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import Foundation

extension AppStep {
    enum Auth: Step {
        case loginRequired
        case loginSuccess
        case registerRequired
        case registerSuccess
        case forgotPassword
        case loginCancelled
    }
}
