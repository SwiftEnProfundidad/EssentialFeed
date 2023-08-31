//
//  RemoteWithLocalFallbackFeedLoaderTest.swift
//  EssentialAppTests
//
//  Created by Juan Carlos Merlos Albarracin on 31/8/23.
//

import XCTest
import EssentialFeed
import EssentialApp

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
class FeedLoaderWithFallbackComposite: FeedLoader {
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
    
    init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
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

class FeedLoaderWithFallbackCompositeTest: XCTestCase {
    
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        // Instanciamos nuestro `sut`, que debe comenzar con un`primaryLoader` y un `fallbackLoader`
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success(fallbackFeed))
        
        expect(sut, toCompleteWith: .success(primaryFeed))
    }
    
    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .success(fallbackFeed))
        
        expect(sut, toCompleteWith: .success(fallbackFeed))
    }
    
    func test_load_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() {
        let sut = makeSUT(primaryResult: .failure(anyNSError()), fallbackResult: .failure(anyNSError()))
        
        expect(sut, toCompleteWith: .failure(anyNSError()))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryResult: FeedLoader.Result, fallbackResult: FeedLoader.Result, file: StaticString = #file, line: UInt = #line) -> FeedLoader {
        // Con este `Stub` (`LoaderStub`), protegemos esta prueba de futuros cambios.
        // Estamos testeando `RemoteWithLocalFallbackFeedLoader` de forma aislada.
        let primaryLoader = LoaderStub(result: primaryResult)
        let fallbackLoader = LoaderStub(result: fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: FeedLoader, toCompleteWith expectedResult: FeedLoader.Result, file: StaticString = #file, line: UInt = #line) {
        // Como estamos capturando un valor, necesitamos una expectativa
        let exp = expectation(description: "Wait for load completion")
        
        // Para capturar el feed recibido, primero debemos invocar a `load` en `sut` y obtener el `Result`
        sut.load { receivedResult in
            // Aquí capturamos el `Feed` recibido
            switch (receivedResult, expectedResult) {
                case let (.success(receivedFeed), .success(expectedFeed)):
                    // Esperamos cargar un `Feed`, así que comparamos un feed recibido con un `Result`, un `RemoteFeed`
                    XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
                    
                case (.failure, .failure):
                    break
                    
                default:
                    XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            // Cumplimos aquí la expectativa
            exp.fulfill()
        }
        
        // Y esperamos la expectativa con un tiempo de espera para
        // asegurarnos que al finalizar la prueba se ejecutó el closure
        wait(for: [exp], timeout: 1.0)
    }
    
    private func uniqueFeed() -> [FeedImage] {
        return [FeedImage(id: UUID(), description: "any", location: "any", url: URL(string: "http://any-url.com")!)]
    }
    
    private class LoaderStub: FeedLoader {
        private let result: FeedLoader.Result
        
        init(result: FeedLoader.Result) {
            self.result = result
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completion(result)
        }
    }
}

// NOTA: Con un ´Stub` establecemos los valores por adelantado y con
// un `Spy` capturamos los valores para que podamos usarlos más tarde
// Los `Stub` son más simples, pero menos precisos sobre los que sucede
// durante los test, por eso son más flexibles. Son buenos, cuando
// tenemos un caso de uso simple.
