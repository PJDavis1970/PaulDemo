//
//  MovieDetailViewModel.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation
import Combine

public class MovieDetailViewModel: ObservableObject {

    @Published public var movieDetail: MovieDetail?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let getMovieDetailUseCase: GetMovieDetailUseCase
    private var cancellables = Set<AnyCancellable>()
    
    public init(getMovieDetailUseCase: GetMovieDetailUseCase, movieId: Int) {
        self.getMovieDetailUseCase = getMovieDetailUseCase
        fetchMovieDetail(movieId: movieId)
    }
    
    public func fetchMovieDetail(movieId: Int) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let detail = try await getMovieDetailUseCase.execute(movieId: movieId)
                await MainActor.run {
                    isLoading = false
                    movieDetail = detail
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    handleError(error)
                }
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                self.errorMessage = "Invalid URL"
            case .noData:
                self.errorMessage = "No data received."
            case .decodingError:
                self.errorMessage = "Failed to parse data.”"
            case .unknown:
                self.errorMessage = "An unknown error occurred."
            }
        } else {
            self.errorMessage = error.localizedDescription
        }
    }
}
