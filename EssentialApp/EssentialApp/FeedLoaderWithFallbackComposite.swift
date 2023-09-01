//
//  FeedLoaderWithFallbackComposite.swift
//  EssentialApp
//
//  Created by Juan Carlos Merlos Albarracin on 1/9/23.
//

import EssentialFeed

// Creamos estos protocolos, abastracciones, que indican la procedencia remota y local del `Feed`
// Con esto recuperamos las garantías de tiempo de compilación y nos indicará el orden correcto
// de los parámetros en caso de que no estén en orden
///protocol RemoteFeedLoader: FeedLoader {}
///protocol LocalFeedLoader: FeedLoader {}

///extension EssentialFeed.RemoteFeedLoader: RemoteFeedLoader {}
///extension EssentialFeed.LocalFeedLoader: LocalFeedLoader {}

// NOTA: podemos pasarle estos dos protocolos al inicializador.
// Decir que esta es una técnica que podemos utilizar para tener la garantía
// en tiempo de compilación. Dado que estamos usando TDD, no hace falta ya
// que tenemos la seguridad de TDD, pero es bueno saber que podemos utilizarlas.

// Utilizamos un `Composite`, es más flexible, para componer
// cualquier `FeedLoader` con otro `FeeLoader` como respaldo (fallback)
public class FeedLoaderWithFallbackComposite: FeedLoader {
    // Aquí no necesitamos exponer los tipos concretos, como `RemoteFeedLoader` o `LocalFeedLoader`
    // Exponemos con abstracciones, que es el `FeedLoader` ya que de exponer con los tipos concretos
    // si estos cambian en un futuro, la prueba se rompería, es decir, `RemoteFeedLoader` podría
    // incluir en un futuro en sus dependencias un `token` pasándoselo al inicializador, con lo que
    // el tipo concreto cambiaría rompiendo los test. Al hacerlo con abstracciones, como con el
    // protocolo `FeedLoader` garantizamos que los test no se romperán. Para ello utilizaremos
    // un `Stub` (`LoaderStub`) y no utilizaremos los tipos concretos `RemoteFeedLoader` y `LocalFeedLoader
    // Un loader principal (`primary`) y un loader alternativo (`fallback`)
    private let primary: FeedLoader
    private let fallback: FeedLoader
    
    public init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        primary.load { [weak self] result in
            switch result {
                case .success:
                    completion(result)
                    
                case .failure:
                    self?.fallback.load(completion: completion)
            }
        }
    }
}
