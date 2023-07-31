//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 9/5/23.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
        
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed() { [weak self] error in
            // Comprobamos que la instancia no haya sido
            // desasignada. Si ha sido desasignada, retornamos.
            guard let self = self else { return }
            
            if let catchDeletionerror = error {
                completion(catchDeletionerror)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = FeedLoader.Result

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            // No tiene efectos secundarios, nos ajustamos al principio de
            // separación de comando-consultas (Command–Query Separation (CQS))
            switch result {
                case let .failure(error):
                    completion(.failure(error))
                case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                    completion(.success(feed.toModels()))
                case .found, .empty:
                    completion(.success([]))
                case .none: break
            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case .failure:
                    self.store.deleteCachedFeed { _ in }
                case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                    self.store.deleteCachedFeed { _ in }
                default: break
            }
        }
    }
}

// Mapeo FeedImage a LocalFeedImage
private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

// Mapeo LocalFeedImage a FeedImage
private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}


