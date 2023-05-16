//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 10/5/23.
//

import Foundation

public enum RetrieveCachedFeedResult {
    case empty
    case found(feed: [LocalFeedImage], tiemestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveCachedFeedResult?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
