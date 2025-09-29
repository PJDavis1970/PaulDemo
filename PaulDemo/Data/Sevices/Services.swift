//
//  Services.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public struct Service {
    private let apiKey = "e59fa91697a3e04422635ab8e092d648"
    private let baseURL = "https://api.themoviedb.org/3"

    public init() {}
    
    public func fetchMovies() async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=en-US&page=1"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)

        do {
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            return response.results
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    public func fetchMovieDetail(movieId: Int) async throws -> MovieDetail {
        let urlString = "\(baseURL)/movie/\(movieId)?api_key=\(apiKey)&language=en-US"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)

        do {
            return try JSONDecoder().decode(MovieDetail.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    public func searchMovies(query: String) async throws -> [Movie] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidURL
        }

        let urlString =
            "\(baseURL)/search/movie?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)&page=1&include_adult=false"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        // Async URLSession
        let (data, _) = try await URLSession.shared.data(from: url)

        do {
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            return response.results
        } catch {
            throw NetworkError.decodingError
        }
    }
}

