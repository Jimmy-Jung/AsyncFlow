//
//  DeepLinkService.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

@MainActor
final class DeepLinkService: Sendable {
    func parseDeepLink(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        switch components.path {
        case "/dashboard":
            return .dashboard

        case "/settings/profile":
            return .settingsProfile

        case "/settings/notifications":
            return .settingsNotifications

        case "/feature":
            // Query parameter로 feature ID 전달
            if let featureIDString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let featureID = UUID(uuidString: featureIDString)
            {
                return .feature(id: featureID)
            }
            return nil

        default:
            return nil
        }
    }
}

enum DeepLink: Equatable, Sendable {
    case dashboard
    case settingsProfile
    case settingsNotifications
    case feature(id: UUID)
}
