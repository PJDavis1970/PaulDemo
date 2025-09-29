//
//  MovieResponse.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public struct MovieResponse: Codable {
    public let results: [Movie]
    
    public init(results: [Movie]) {
        self.results = results
    }
}
