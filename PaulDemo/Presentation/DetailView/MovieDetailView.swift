//
//  MovieDetailView.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import SwiftUI
import Kingfisher

struct MovieDetailView: View {
    @StateObject private var viewModel: MovieDetailViewModel
    
    init(viewModel: MovieDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let posterPath = viewModel.movieDetail?.posterPath,
                   let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 300)
                        .foregroundColor(.gray)
                }
                
                HStack(){
                    Text(viewModel.movieDetail?.title ?? "Unknown Title")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                }
                
                Text(viewModel.movieDetail?.overview ?? "No overview available.")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding()
        }
        .navigationTitle(viewModel.movieDetail?.title ?? "Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}
