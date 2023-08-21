//
//  FeedImageDataLoader.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 21/8/23.
//

import Foundation

public protocol FeedImageDataLoaderTask {
    func cancel()
}

// Con el protocolo `FeedImageDataLoaderTask` hacemos que las implementaciones de
// `FeedImageDataLoader` no estén obligadas a tener estado, lo hacen los clientes.
public protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask
}
