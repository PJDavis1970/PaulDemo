//
//  MovieListViewModel.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation
import Combine

public class MovieListViewModel: ObservableObject {
    @Published public var movies: [Movie] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var searchText: String = ""
    
    private let getMoviesUseCase: GetMoviesUseCase
    private let searchMoviesUseCase: SearchMoviesUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(getMoviesUseCase: GetMoviesUseCase, searchMoviesUseCase: SearchMoviesUseCase) {
        self.getMoviesUseCase = getMoviesUseCase
        self.searchMoviesUseCase = searchMoviesUseCase
        setupBindings()
        fetchMovies()
    }

    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.fetchMovies()
                } else {
                    self.searchMovies(query: query)
                }
            }
            .store(in: &cancellables)
    }

    public func fetchMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let movies = try await getMoviesUseCase.execute()
                await MainActor.run {
                    self.isLoading = false
                    self.movies = movies
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }

    public func searchMovies(query: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let movies = try await searchMoviesUseCase.execute(query: query)
                await MainActor.run {
                    self.isLoading = false
                    self.movies = movies
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error)
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

extension String: Identifiable {
    public var id: String { self }
}
