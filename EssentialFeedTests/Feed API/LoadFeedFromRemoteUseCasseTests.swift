//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 29/4/23.
//

import XCTest
import EssentialFeed

class LoadFeedFromRemoteUseCasseTests: XCTestCase {
    
    // Hacemos el mínimo test para el inicializador del caso de uso
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // Ahora el caso de uso para la carga de FeedImages
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    // Hacemos dos llamadas, es decir, a dos url's
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    // El caso de uso cuando entrega un error dado que no hay
    // `response`ya que no tenemos conectividad a internet.
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    // El caso de uso cuando entrega un error dado que la
    // `response` es distinto de un 200 según el caso de uso
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        let json = makeItemsJSON([])
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    // El caso de uso cuando tenemos un 200 pero el JSON no es válido
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    // El caso de uso cuando tenemos un 200 y el JSON es válido pero viene vacío
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    // El caso de uso cuando tenemos un 200 y el JSON es válido y viene con datos
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "http://another-url.com")!)
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items), when: {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    // Garantizamos que no entregaremos un resultado (invocaremos el cierre de finalización)
    // después de que se haya desasignado la instancia de `RemoteFeedLoader`
    func test_load_doesNotDeliversResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults: [FeedLoader.Result] = []
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers - CÓDIGO DE TESTEO
    
    /// Method Factory
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    /// Al usar `Method Factory` en el alcance de la prueba, también evitamos que nuestros métodos de
    /// prueba se rompan en el futuro si alguna vez decidimos cambiar los tipos de producción nuevamente
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    /// Method Factory for items
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    
    /// Method Factory for items json
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result,
                        when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        // Necesitamos expectativas dado que el código es asíncrono y de que solo se ejecute una vez
        // Sabemos que se cumple la expectación `fullfill`, dado que si no, tendríamos un fallo en `wait`.
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receiveResult in
            // Utilizamos la coincidencia de patrones de Swift
            switch (receiveResult, expectedResult) {
                    // Podemo comparar los items, dado que `FeedImage` se ajusta a `Equatable`
                    // de lo contrario, el test fallará al no poder comparar los `items`
                case let (.success(receiveItems), .success(expectedItems)):
                    XCTAssertEqual(receiveItems, expectedItems, file: file, line: line)
                    
                case let (.failure(receiveError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                    XCTAssertEqual(receiveError, expectedError, file: file, line: line)
                default:
                    XCTFail("Expected result \(expectedResult) got \(receiveResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
/// Clase espía para simular los datos, espiar, de nuestra `HTTPClient`de producción
private class HTTPClientSpy: HTTPClient {
    private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    
    // Colección de urls, puede ser que llamemos a más de una URL,
    // las almacenamos en un array que devuelve las url's de `message`
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    // Implementamos el método get con lo que tenemos ahora para comprobar o testear
    func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
        messages.append((url, completion))
    }
    
    // Obtener el error del array de `messges` en un índice
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    // Obtener los datos y la respuesta del array `messages` en un índice dado
    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        messages[index].completion(.success(data, response))
    }
}
