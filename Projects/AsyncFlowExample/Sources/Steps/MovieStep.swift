//
//  MovieStep.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow

/// Movie 앱의 네비게이션 Step
enum MovieStep: Step {
    // App
    case appLaunch

    // Movie List
    case movieList
    case movieDetail(id: Int)

    // Search
    case search
    case searchResult(query: String)
}
