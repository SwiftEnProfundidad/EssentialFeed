//
//  FeedCache.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 2/9/23.
//

import Foundation

public protocol FeedCache {
    typealias Result = Swift.Result<Void, Error>
    
    func save(_ feed: [FeedImage], completion: @escaping (Result) -> Void)
}
