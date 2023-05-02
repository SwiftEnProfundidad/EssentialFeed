//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTest: XCTestCase {
    
    // Hacemos el mínimo test para el inicializador del caso de uso
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // Ahora el caso de uso para la carga de FeedItems
    func test_load_requestsDataFromURL() {
        /// Arrange: `Given`, dado un cliente y un sut
        let url = URL(string: "https://a.given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        /// Act: `When` Cuando invocamos `sut.load()`
        sut.load() { _ in }
        
        /// Assert: `Then` entonces afirmamos que una
        /// request con URL fue iniciada en el `client`
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    // Hacemos dos llamadas, es decir, a dos url's
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a.given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load() { _ in }
        sut.load() { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    // El caso de uso cuando entrega un error dado que no hay
    // `response`ya que no tenemos conectividad a internet.
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .connectivity, when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    // El caso de uso cuando entrega un error dado que la
    // `response` es distinto de un 200 según el caso de uso
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithError: .invalidData, when: {
                client.complete(withStatusCode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .invalidData, when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
//    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
//
//    }
    
    // MARK: - Helpers - CÓDIGO DE TESTEO
    
    /// Method factory
    private func makeSUT(url: URL = URL(string: "https://a.given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void,
                        file: StaticString = #filePath, line: UInt = #line) {
        var captureResult = [RemoteFeedLoader.Result]()
        sut.load { captureResult.append($0) }
        
        action()
        
        XCTAssertEqual(captureResult, [.failure(error)], file: file, line: line)
    }
}

// Clase espía para simular los datos, espiar, de nuestra `HTTPClient`de producción
private class HTTPClientSpy: HTTPClient {
    private var message = [(url: URL, completion: (HTTPCllientResult) -> Void)]()
    
    // Colección de urls, puede ser que llamemos a más de una URL,
    // las almacenamos en un array que devuelve las url's de `message`
    var requestedURLs: [URL] {
        return message.map { $0.url }
    }
    
    // Implementamos el método get con lo que tenemos ahora para comprobar o testear
    func get(from url: URL, completion: @escaping (HTTPCllientResult) -> Void) {
        message.append((url, completion))
    }
    
    // Creamos esta función para devolver el primer error del array de errores y testearla
    func complete(with error: Error, at index: Int = 0) {
        message[index].completion(.failure(error))
    }
    
    func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        message[index].completion(.success(data, response))
    }
}
