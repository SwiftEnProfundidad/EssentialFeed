//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 30/4/23.
//

import Foundation

// Creamos esta enum para evitar tener
// casos de más y que no están reflejados
// en nuestro contrato y evitar los opcionales
// como podría ser tener `HTTPURLResponse`
// y `Error` de tipo opcional, ya que de ser así,
// tendríamos cuatro casos, `HTTPURLResponse` que podría
// traer nil o un valor y `Error` también nil o valor, con
// lo que serían cuatro casos. Con esta enum, solo tenemos
// dos casos, un `success` o un `failure` y sin opcionales,
// eliminando así dos estados inválidos.
public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
                case let .success(data, response):
                    do {
                        let items = try FeedItemMapper.map(data, response)
                        completion(.success(items))
                    } catch  {
                        completion(.failure(.invalidData))
                    }
                case .failure:
                    completion(.failure(.connectivity))
            }
        }
    }
}

private class FeedItemMapper {
    private struct Root: Decodable {
        let items: [Item]
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
    
    static var OK_200: Int { return 200 }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map { $0.item }
     }
}
