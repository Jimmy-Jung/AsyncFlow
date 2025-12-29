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
final class MovieListViewModel: ObservableObject {
    // MARK: - Published State

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

    // MARK: - Properties

    private var stepContinuation: AsyncStream<MovieStep>.Continuation?

    // MARK: - Methods

    func send(_ input: Input) {
        switch input {
        case .viewDidLoad:
            loadMovies()
        case let .movieTapped(id):
            stepContinuation?.yield(.movieDetail(id: id))
        case .searchButtonTapped:
            stepContinuation?.yield(.search)
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

// MARK: - Stepper

extension MovieListViewModel: Stepper {
    typealias StepType = MovieStep

    var steps: AsyncStream<MovieStep> {
        AsyncStream { [weak self] continuation in
            self?.stepContinuation = continuation
        }
    }
}
