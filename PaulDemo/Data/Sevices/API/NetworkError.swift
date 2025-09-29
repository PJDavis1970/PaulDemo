//
//  NetworkError.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation

public enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unknown
}
