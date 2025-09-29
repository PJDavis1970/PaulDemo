//
//  MovieRepository.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public protocol MovieRepository {
    func getMovies() async throws -> [Movie]
    func searchMovies(query: String) async throws -> [Movie]
    func getMovieDetail(movieId: Int) async throws -> MovieDetail
}
