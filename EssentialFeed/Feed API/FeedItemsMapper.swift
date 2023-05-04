//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 3/5/23.
//

import Foundation

internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            return items.map { $0.item }
        }
    }
    // Move Decodable logic to a new private item struct to
    // decouple the Feed Feature module from API implementation details
    // Antes estaba en el propio tipo `FeedItems`, el módulo `FeedFeature`
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: image)
        }
    }
    
    private static var OK_200: Int { return 200 }
    
    // La hacemos `static` ya que no necesitamos una instancia o llamar a `self` para acceder a `FeedItemsMap`
    // De ahí que los test pasen, al comprobar que tanto `sut` como `client` son
    // `nil` una vez se ha llevado el testeo de estas (en `addTeardownBlock`de los test)
    internal static func map(_ data: Data, from response: HTTPURLResponse) -> Result<[FeedItem], RemoteFeedLoader.Error> {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.feed)
        
    }
}
