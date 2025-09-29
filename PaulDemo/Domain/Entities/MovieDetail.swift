//
//  MovieDetail.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public struct MovieDetail: Codable, Identifiable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let releaseDate: String
    public let runtime: Int?
    public let genres: [Genre]
    public let voteAverage: Double
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case runtime, genres
        case voteAverage = "vote_average"
    }
}

public struct Genre: Codable, Identifiable {
    public let id: Int
    public let name: String
}


