//
//  GetPopularMoviesUseCase.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public class GetMoviesUseCase {
    private let repository: MovieRepository

    public init(repository: MovieRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Movie] {
        try await repository.getMovies()
    }
}
