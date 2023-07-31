//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 10/5/23.
//

import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    typealias RetrievalResult = Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult?) -> Void
    
    /// The completion handler can be invoked in any trhead.
    /// Clients are responsible to dispatch to appropriate trheads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    
    /// The completion handler can be invoked in any trhead.
    /// Clients are responsible to dispatch to appropriate trheads, if needed.
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    
    /// The completion handler can be invoked in any trhead.
    /// Clients are responsible to dispatch to appropriate trheads, if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}
