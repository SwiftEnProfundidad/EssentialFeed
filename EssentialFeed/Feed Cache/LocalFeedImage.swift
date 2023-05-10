//
//  LocalFeedImage.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 10/5/23.
//

import Foundation

// Este es un espejo del modelo de datos `FeedImage`, pero para una representación local
// Con ello conseguimos que `FeedStroe` no tenga un acoplamiento con el type `FeedImage`
// Conseguimos una descentralización entre módulos, con lo que podemos desarrollar diferentes
// módulos en paralelo sin afectarse entre ellos. Esta técnica de denomina DTO's.
public struct LocalFeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
