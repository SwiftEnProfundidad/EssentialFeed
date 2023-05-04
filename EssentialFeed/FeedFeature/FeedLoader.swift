//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import Foundation

public protocol FeedLoader {
    func load(completion: @escaping (Result<[FeedItem], RemoteFeedLoader.Error>) -> Void)
}
