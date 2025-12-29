//
//  PermissionService.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

@MainActor
final class PermissionService: Sendable {
    enum Permission: Sendable {
        case camera
        case location
        case photoLibrary
        case contacts
        case notifications
    }

    private var grantedPermissions: Set<Permission> = []

    func checkPermission(_ permission: Permission) async -> Bool {
        // Mock 구현: 0.2초 딜레이
        try? await Task.sleep(nanoseconds: 200_000_000)

        return grantedPermissions.contains(permission)
    }

    func requestPermission(_ permission: Permission) async -> Bool {
        // Mock 구현: 시뮬레이션된 권한 요청
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 50% 확률로 권한 부여
        let granted = Bool.random()

        if granted {
            grantedPermissions.insert(permission)
        }

        return granted
    }

    func revokePermission(_ permission: Permission) {
        grantedPermissions.remove(permission)
    }
}
