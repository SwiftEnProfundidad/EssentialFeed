//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 10/5/23.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

// Este es un espejo del modelo de datos `FeedItem`, pero para una representación local
// Con ello conseguimos que `FeedStroe` no tenga un acoplamiento con el type `FeedItem`
// Conseguimos una descentralización entre módulos, con lo que podemos desarrollar diferentes
// módulos en paralelo sin afectarse entre ellos. Esta técnica de denomina DTO's.
public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
