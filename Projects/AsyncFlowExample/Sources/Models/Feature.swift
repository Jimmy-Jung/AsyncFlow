//
//  Feature.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

struct Feature: Equatable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let requiresPermission: Bool

    static var mockFeatures: [Feature] {
        [
            Feature(
                id: UUID(),
                name: "Camera Scanner",
                description: "QR 코드 및 바코드 스캔 기능",
                icon: "camera.fill",
                requiresPermission: true
            ),
            Feature(
                id: UUID(),
                name: "Location Tracker",
                description: "실시간 위치 추적 및 지도 표시",
                icon: "location.fill",
                requiresPermission: true
            ),
            Feature(
                id: UUID(),
                name: "Data Sync",
                description: "클라우드 데이터 동기화",
                icon: "arrow.triangle.2.circlepath",
                requiresPermission: false
            ),
            Feature(
                id: UUID(),
                name: "Push Notifications",
                description: "푸시 알림 설정 및 관리",
                icon: "bell.fill",
                requiresPermission: true
            ),
            Feature(
                id: UUID(),
                name: "Photo Library",
                description: "사진 라이브러리 접근",
                icon: "photo.fill",
                requiresPermission: true
            ),
            Feature(
                id: UUID(),
                name: "Contacts",
                description: "연락처 접근 및 관리",
                icon: "person.crop.circle.fill",
                requiresPermission: true
            ),
        ]
    }
}
