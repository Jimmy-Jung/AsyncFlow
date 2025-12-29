//
//  MovieListViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Combine
import Foundation

@MainActor
final class MovieListViewModel: ObservableObject, Stepper {
    // MARK: - Published State

    @StepEmitter var stepEmitter: StepEmitter<MovieStep>
    @Published var state = State()

    // MARK: - Types

    enum Input: Sendable {
        case viewDidLoad
        case movieTapped(id: Int)
        case searchButtonTapped
    }

    struct State: Equatable, Sendable {
        var movies: [Movie] = []
        var isLoading: Bool = false
    }

    // MARK: - Methods

    func send(_ input: Input) {
        switch input {
        case .viewDidLoad:
            loadMovies()
        case let .movieTapped(id):
            emit(.movieDetail(id: id))
        case .searchButtonTapped:
            emit(.search)
        }
    }

    private func loadMovies() {
        state.isLoading = true

        Task {
            try await Task.sleep(for: .seconds(0.5))
            state.movies = Movie.mockList
            state.isLoading = false
        }
    }
}
