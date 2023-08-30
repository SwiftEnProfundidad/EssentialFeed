//
//  RemoteWithLocalFallbackFeedLoaderTest.swift
//  EssentialAppTests
//
//  Created by Juan Carlos Merlos Albarracin on 31/8/23.
//

import XCTest
import EssentialFeed

// Creamos estos protocolos, abastracciones, que indican la procedencia remota y local del `Feed`
// Con esto recuperamos las garantías de tiempo de compilación y nos indicará el orden correcto
// de los parámetros en caso de que no estén en orden
///protocol RemoteFeedLoader: FeedLoader {}
///protocol LocalFeedLoader: FeedLoader {}

///extension EssentialFeed.RemoteFeedLoader: RemoteFeedLoader {}
///extension EssentialFeed.LocalFeedLoader: LocalFeedLoader {}

// NOTA: podemos pasarle estos dos protocolos al inicializador.
// Decir que esta es una técnica que podemos utilizar tener la garantía
// en tiempo de compilación. Dado que estamos usando TDD, no hace falta
// ya que tenemos la seguridad de TDD, pero es bueno saber que podemos
// utilizar estas técnicas también.

// Utilizamos un `Composite`, es más flexible, para componer cualquier `FeedLoader` con otro `FeeLoader` como respaldo
class FeedLoaderWithFallbackComposite {
    // Aquí no necesitamos exponer los tipos concretos, como `RemoteFeedLoader` o `LocalFeedLoader`
    // Exponemos con abstracciones, que es el `FeedLoader` ya que de exponer con los tipos concretos
    // si estos cambian en un futuro, la prueba se rompería, es decir, `RemoteFeedLoader` podría
    // incluir en un futuro en sus dependencias un `token` pasándoselo al inicializador, con lo que
    // el tipo concreto cambiaría rompiendo los test. Al hacerlo con abstracciones, como con el
    // protocolo `FeedLoader` garantizamos que los test no se romperán. Para ello utilizaremos
    // un `Stub` (`LoaderStub`) y no utilizaremos los tipos concretos `RemoteFeedLoader` y `LocalFeedLoader
    // Un loader principal (`primary`) y un loader alternativo (`fallback`)
    init(primary: FeedLoader, fallback: FeedLoader) {
        
    }
}

class FeedLoaderWithFallbackCompositeTest: XCTestCase {
    
    func test_load_deliversRemoteFeedOnRemoteSuccess() {
        // Con estos `Stub` protegemos esta prueba de futuros cambios.
        // Estamos testeando `RemoteWithLocalFallbackFeedLoader` de forma aislada.
        let primaryLoader = LoaderStub()
        let fallbackLoader = LoaderStub()
        
        // Instanciamos nuestro `sut`, que debe comenzar con un`RemoteLoader` y un `LocalLoader`
        let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        
        // Como estamos capturando un valor, necesitamos una expectativa
        let exp = expectation(description: "Wait for load completion")
        
        // Para capturar el feed recibido, primero debemos invocar a `load` en `sut` y obtener el `Result`
        sut.load { result in
            // Aquí capturamos el `Feed` recibido
            switch result {
                case let .success(receivedFeed):
                    // Esperamos cargar un `Feed`, así que comparamos un feed recibido con un `Result`, un `RemoteFeed`
                    XCTAssertEqual(receivedFeed, remoteFeed)
                    
                case .failure:
                    XCTFail("Expected successful load feed result, got \(result) instead")
            }
            
            // Cumplimos aquí la expectativa
            exp.fulfill()
        }
        // Y esperamos la expectativa con un tiempo de espera para
        // asegurarnos que al finalizar la prueba se ejecutó el closure.
        wait(for: [exp], timeout: 1)
    }
    
    private class LoaderStub: FeedLoader {
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            
        }
    }
}
