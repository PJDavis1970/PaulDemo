//
//  ContentView.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    let getMoviesUseCase: GetMoviesUseCase
    let getMovieDetailUseCase: GetMovieDetailUseCase
    let searchMoviesUseCase: SearchMoviesUseCase

    var body: some View {
        MovieListView(
            viewModel: MovieListViewModel(
                getMoviesUseCase: getMoviesUseCase,
                searchMoviesUseCase: searchMoviesUseCase
            ),
            getMovieDetailUseCase: getMovieDetailUseCase
        )
    }
}
