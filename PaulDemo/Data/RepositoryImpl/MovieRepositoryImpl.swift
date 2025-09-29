//
//  MovieRepositoryImpl.swift
//  PaulDemo
//
//  Created by Paul Davis on 28/09/2025.
//

import Foundation
import CoreData

public class MovieRepositoryImpl: MovieRepository {
    private let service: Service
    private let persistentContainer: NSPersistentContainer
    
    public init(service: Service, persistentContainer: NSPersistentContainer) {
        self.service = service
        self.persistentContainer = persistentContainer
    }
    
    public func getMovies() async throws -> [Movie] {
        do {
            let movies = try await service.fetchMovies()
            saveMoviesToCoreData(movies: movies)
            return movies
        } catch {
            let cached = fetchMoviesFromCoreData()
            if !cached.isEmpty { return cached }
            throw error
        }
    }
    
    public func searchMovies(query: String) async throws -> [Movie] {
        try await service.searchMovies(query: query)
    }
    
    public func getMovieDetail(movieId: Int) async throws -> MovieDetail {
        do {
            let detail = try await service.fetchMovieDetail(movieId: movieId)
            return detail
        } catch {
            if let cached = fetchMovieDetailFromCoreData(movieId: movieId) {
                return cached
            }
            throw error
        }
    }
    
    private func saveMoviesToCoreData(movies: [Movie]) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MovieEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Failed to delete existing movies: \(error)")
        }
        
        for movie in movies {
            let movieEntity = MovieEntity(context: context)
            movieEntity.id = Int64(movie.id)
            movieEntity.title = movie.title
            movieEntity.overview = movie.overview
            movieEntity.posterPath = movie.posterPath
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save movies: \(error)")
        }
    }
    
    private func fetchMoviesFromCoreData() -> [Movie] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        do {
            let movieEntities = try context.fetch(fetchRequest)
            return movieEntities.map { $0.toDomain() }
        } catch {
            print("Failed to fetch movies from Core Data: \(error)")
            return []
        }
    }
    
    
    private func fetchMovieDetailFromCoreData(movieId: Int) -> MovieDetail? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", movieId)
        return nil
    }
}



