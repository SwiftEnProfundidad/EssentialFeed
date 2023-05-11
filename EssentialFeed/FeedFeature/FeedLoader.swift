//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
