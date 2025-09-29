//
//  MovieDetailExt.swift
//  PaulDemo
//
//  Created by Paul Davis on 29/09/2025.
//

import Foundation

extension MovieDetail {
    
    func toMovieDetail() -> MovieDetail {
        return MovieDetail(
            id: Int(self.id),
            title: self.title,
            overview: self.overview,
            posterPath: self.posterPath,
            releaseDate: self.releaseDate,
            runtime: self.runtime,
            genres: self.genres,
            voteAverage: self.voteAverage
        )
    }
}
