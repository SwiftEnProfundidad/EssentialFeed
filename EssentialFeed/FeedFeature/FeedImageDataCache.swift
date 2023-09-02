//
//  FeedImageDataCache.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 2/9/23.
//

import Foundation

public protocol FeedImageDataCache {
    typealias Result = Swift.Result<Void, Error>
    
    func save(_ data: Data, for url: URL, completion: @escaping (Result) -> Void)
}
