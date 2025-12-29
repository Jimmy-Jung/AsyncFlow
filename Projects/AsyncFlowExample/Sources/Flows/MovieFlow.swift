//
//  MovieFlow.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import UIKit

final class MovieFlow: Flow {
    typealias StepType = MovieStep

    // MARK: - Properties

    var root: any Presentable { navigationController }
    private let navigationController = UINavigationController()

    // MARK: - Flow

    func navigate(to step: MovieStep) async -> FlowContributors<MovieStep> {
        switch step {
        case .appLaunch:
            return .none

        case .movieList:
            return navigateToMovieList()

        case let .movieDetail(id):
            return navigateToMovieDetail(id: id)

        case .search:
            return navigateToSearch()

        case let .searchResult(query):
            return navigateToSearchResult(query: query)
        }
    }

    // MARK: - Private Methods

    private func navigateToMovieList() -> FlowContributors<MovieStep> {
        let viewModel = MovieListViewModel()
        let viewController = MovieListViewController(viewModel: viewModel)

        navigationController.setViewControllers([viewController], animated: false)

        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }

    private func navigateToMovieDetail(id: Int) -> FlowContributors<MovieStep> {
        let viewModel = MovieDetailViewModel(movieId: id)
        let viewController = MovieDetailViewController(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        return .one(.contribute(presentable: viewController, stepper: viewModel))
    }

    private func navigateToSearch() -> FlowContributors<MovieStep> {
        // 간단한 Alert로 구현
        let alert = UIAlertController(
            title: "Search",
            message: "Search feature will be implemented",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        navigationController.present(alert, animated: true)

        return .none
    }

    private func navigateToSearchResult(query _: String) -> FlowContributors<MovieStep> {
        // 추후 구현
        return .none
    }
}
