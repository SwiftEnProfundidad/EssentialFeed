//
//  FeedLoaderCacheDecorator.swift
//  EssentialApp
//
//  Created by Juan Carlos Merlos Albarracin on 2/9/23.
//

import EssentialFeed

// Este decorator todo lo que hace es inyectar la operación de guardado (`save`) en el `decoratee.load`
// por lo que el `decorator` no necestia saber sobre guardar o almacenar en caché y el caché no necesita
// saber sobre la carga (`load`), con lo que nuestros `composite` sigue siendo componible, no depende de
// tipos concretos y el `Decorator` es también componible porque dependemos de abstracciones (`Protocol`)
public final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let cache: FeedCache
    
    public init(decoratee: FeedLoader, cache: FeedCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        decoratee.load { [weak self] result in
            // if let feed = try? result.get() {
            //      self?.cache.save(feed) { _ in }
            // }
            // Se puede hacer con `map` si no nos gustan los `if`
            completion(result.map { feed in
                self?.cache.saveIgnoringResult(feed)
                return feed
            })
        }
    }
}

private extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed) { _ in }
    }
}
