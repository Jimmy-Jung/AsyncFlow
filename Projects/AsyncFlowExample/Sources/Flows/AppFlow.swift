//
//  AppFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import UIKit

final class AppFlow: Flow {
    typealias StepType = MovieStep

    // MARK: - Properties

    var root: any Presentable { window }
    private let window: UIWindow
    private var movieFlow: MovieFlow?

    // MARK: - Initialization

    init(window: UIWindow) {
        self.window = window
    }

    // MARK: - Flow

    func navigate(to step: MovieStep) async -> FlowContributors<MovieStep> {
        switch step {
        case .appLaunch:
            return await navigateToMovieApp()
        case .movieList, .movieDetail, .search, .searchResult:
            // MovieFlow에게 위임
            if let movieFlow = movieFlow {
                return await movieFlow.navigate(to: step)
            }
            return .none
        }
    }

    // MARK: - Private Methods

    private func navigateToMovieApp() async -> FlowContributors<MovieStep> {
        let movieFlow = MovieFlow()
        self.movieFlow = movieFlow

        print("🔍 AppFlow: Setting rootViewController")
        print("🔍 AppFlow: MovieFlow.root.viewController = \(movieFlow.root.viewController)")

        window.rootViewController = movieFlow.root.viewController
        window.makeKeyAndVisible()

        print("🔍 AppFlow: Window is key: \(window.isKeyWindow)")
        print("🔍 AppFlow: RootViewController: \(String(describing: window.rootViewController))")

        // MovieFlow 초기화
        let contributors = await movieFlow.navigate(to: .movieList)

        return contributors
    }
}
