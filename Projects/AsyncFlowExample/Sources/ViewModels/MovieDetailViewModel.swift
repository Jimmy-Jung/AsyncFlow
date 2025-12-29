//
//  MovieDetailViewModel.swift
//  AsyncFlowExample
//
//  Created by 정준영 on 2025. 12. 29.
//

import AsyncFlow
import AsyncViewModel
import Combine
import Foundation

@MainActor
final class MovieDetailViewModel: ObservableObject, Stepper {
    // MARK: - Published State

    @StepEmitter var stepEmitter: StepEmitter<MovieStep>
    @Published var state = State()

    // MARK: - Types

    enum Input: Sendable {
        case viewDidLoad
    }

    struct State: Equatable, Sendable {
        var movie: Movie?
        var isLoading: Bool = false
    }

    // MARK: - Properties

    private let movieId: Int

    // MARK: - Initialization

    init(movieId: Int) {
        self.movieId = movieId
    }

    // MARK: - Methods

    func send(_ input: Input) {
        switch input {
        case .viewDidLoad:
            loadMovie()
        }
    }

    private func loadMovie() {
        state.isLoading = true

        Task {
            try await Task.sleep(for: .seconds(0.3))
            let movie = Movie.mockList.first { $0.id == movieId } ?? Movie.mock1
            state.movie = movie
            state.isLoading = false
        }
    }
}
