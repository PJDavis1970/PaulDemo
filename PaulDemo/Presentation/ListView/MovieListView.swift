//
//  MovieListView.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import SwiftUI
import Kingfisher

struct MovieListView: View {
    @ObservedObject var viewModel: MovieListViewModel
    let getMovieDetailUseCase: GetMovieDetailUseCase
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else {
                    List(viewModel.movies) { movie in
                        NavigationLink(destination: createDetailView(for: movie)) {
                            HStack(alignment: .top) {
                                if let posterPath = movie.posterPath,
                                   let url = URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)") {
                                    KFImage(url)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 75)
                                        .cornerRadius(4)
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 75)
                                        .foregroundColor(.gray)
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(movie.title)
                                        .font(.headline)
                                    Text(movie.overview)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Popular Movies")
            .alert(item: $viewModel.errorMessage) { errorMessage in
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    @ViewBuilder
    private func createDetailView(for movie: Movie) -> some View {
        let detailViewModel = MovieDetailViewModel(
            getMovieDetailUseCase: getMovieDetailUseCase,
            movieId: movie.id
        )
        MovieDetailView(viewModel: detailViewModel)
    }
}
