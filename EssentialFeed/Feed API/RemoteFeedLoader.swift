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
public enum HTTPCllientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPCllientResult) -> Void)
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
                case let .success(data, _):
                    if let _ = try? JSONSerialization.jsonObject(with: data) {
                        completion(.success([]))
                    } else {
                        completion(.failure(.invalidData))
                    }
                case .failure:
                    completion(.failure(.connectivity))
            }
        }
    }
}
