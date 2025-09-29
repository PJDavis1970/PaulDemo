//
//  GetMovieDetailUseCase.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public class GetMovieDetailUseCase {

    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    public func execute(movieId: Int) async throws -> MovieDetail {
        try await repository.getMovieDetail(movieId: movieId)
    }
}
