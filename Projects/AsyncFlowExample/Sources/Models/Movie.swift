//
//  Movie.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import Foundation

struct Movie: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String
    let rating: Double
    let posterPath: String?

    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}

// MARK: - Mock Data

extension Movie {
    static let mock1 = Movie(
        id: 1,
        title: "Inception",
        overview: "A thief who steals corporate secrets through the use of dream-sharing technology.",
        releaseDate: "2010-07-16",
        rating: 8.8,
        posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg"
    )

    static let mock2 = Movie(
        id: 2,
        title: "The Dark Knight",
        overview: "When the menace known as the Joker wreaks havoc on Gotham.",
        releaseDate: "2008-07-18",
        rating: 9.0,
        posterPath: "/qJ2tW6WMUDux911r6m7haRef0WH.jpg"
    )

    static let mock3 = Movie(
        id: 3,
        title: "Interstellar",
        overview: "A team of explorers travel through a wormhole in space.",
        releaseDate: "2014-11-07",
        rating: 8.6,
        posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"
    )

    static let mockList = [mock1, mock2, mock3]
}
