//
//  User.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

struct User: Equatable, Sendable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?

    static var mock: User {
        User(
            id: UUID(),
            name: "정준영",
            email: "joony300@gmail.com",
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/example")
        )
    }
}
