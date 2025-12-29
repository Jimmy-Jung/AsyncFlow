//
//  AnalyticsService.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import Foundation

@MainActor
final class AnalyticsService: Sendable {
    private var events: [AnalyticsEvent] = []

    func trackNavigation(_ event: NavigationEvent) {
        let analyticsEvent = AnalyticsEvent(
            name: "navigation",
            properties: [
                "flow": event.flowType,
                "step": event.stepDescription,
            ]
        )

        track(analyticsEvent)
    }

    func trackScreen(_ screenName: String) {
        let event = AnalyticsEvent(
            name: "screen_view",
            properties: ["screen_name": screenName]
        )

        track(event)
    }

    func trackAction(_ action: String, properties: [String: String] = [:]) {
        let event = AnalyticsEvent(
            name: action,
            properties: properties
        )

        track(event)
    }

    private func track(_ event: AnalyticsEvent) {
        events.append(event)
        print("📊 Analytics: \(event.name) - \(event.properties)")
    }

    func getEvents() -> [AnalyticsEvent] {
        events
    }
}

struct AnalyticsEvent: Sendable {
    let id: UUID = .init()
    let timestamp: Date = .init()
    let name: String
    let properties: [String: String]
}
