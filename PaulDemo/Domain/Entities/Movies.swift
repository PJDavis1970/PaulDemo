//
//  Movies.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public struct Movie: Identifiable, Codable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    
    public init(id: Int, title: String, overview: String, posterPath: String?) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
    }
}
