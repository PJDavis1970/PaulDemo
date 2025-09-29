//
//  PaulDemoApp.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import SwiftUI

@main
struct PaulDemoApp: App {
    let persistentContainer = CoreDataStack.shared.persistentContainer
    let service = Service()
    let movieRepository: MovieRepository
    let getMoviesUseCase: GetMoviesUseCase
    let searchMoviesUseCase: SearchMoviesUseCase
    let getMovieDetailUseCase: GetMovieDetailUseCase
    
    init() {
        movieRepository = MovieRepositoryImpl(service: service, persistentContainer: persistentContainer)
        getMoviesUseCase = GetMoviesUseCase(repository: movieRepository)
        searchMoviesUseCase = SearchMoviesUseCase(repository: movieRepository)
        getMovieDetailUseCase = GetMovieDetailUseCase(repository: movieRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                getMoviesUseCase: getMoviesUseCase,
                getMovieDetailUseCase: getMovieDetailUseCase,
                searchMoviesUseCase: searchMoviesUseCase
            )
            .environment(\.managedObjectContext, persistentContainer.viewContext)
        }
    }
}
