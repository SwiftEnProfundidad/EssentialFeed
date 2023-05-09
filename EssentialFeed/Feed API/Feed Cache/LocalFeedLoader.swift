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
    
    public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed() { [weak self] error in
            // Comprobamos que la instancia no haya sido desasignada
            // Si ha sido desasignada, retornamos.
            guard let self = self else { return }
            
            if let catchDeletionerror = error {
                completion(catchDeletionerror)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
