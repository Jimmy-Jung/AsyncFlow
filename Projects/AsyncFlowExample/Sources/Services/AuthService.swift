//
//  AuthService.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

@MainActor
final class AuthService: Sendable {
    private var _isLoggedIn = false
    private var _currentUser: User?

    var isLoggedIn: Bool {
        _isLoggedIn
    }

    var currentUser: User? {
        _currentUser
    }

    func login(email: String, password: String) async throws -> User {
        // Mock 구현: 0.5초 딜레이
        try await Task.sleep(nanoseconds: 500_000_000)

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        let user = User.mock
        _currentUser = user
        _isLoggedIn = true

        return user
    }

    func register(name: String, email: String, password: String) async throws -> User {
        // Mock 구현: 0.5초 딜레이
        try await Task.sleep(nanoseconds: 500_000_000)

        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        let user = User(
            id: UUID(),
            name: name,
            email: email,
            avatarURL: nil
        )

        _currentUser = user
        _isLoggedIn = true

        return user
    }

    func logout() {
        _isLoggedIn = false
        _currentUser = nil
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case invalidInput
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "이메일 또는 비밀번호가 올바르지 않습니다"
        case .invalidInput:
            return "모든 필드를 입력해주세요"
        case .networkError:
            return "네트워크 오류가 발생했습니다"
        }
    }
}
