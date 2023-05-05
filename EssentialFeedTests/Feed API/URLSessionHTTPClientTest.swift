//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/5/23.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTest: XCTestCase {
    
    // Caso de uso para que una `dataTask comience a llamar a `resume`.
    func test_getFromURL_resumeDataTaskWhitURL() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        // Le decimos a la `session` que devuelva nuestra `task` para una URL dada.
        // Para ello creamos un mecanismo de `stubing` para que dtubing la URL con una `task`
        session.stub(url: url, task: task)
        
        let sut = URLSessionHTTPClient(session: session)
        
        // Aquí ignoramos la respuesta
        sut.get(from: url) { _ in }
        
        // Afirmamos que `resume`de `dataTask` se llama una vez, de lo contrario habrá un error.
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    // Caso de uso en el que la URL falla en las solicitudes
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any eror", code: 1)
        let session = URLSessionSpy()
        session.stub(url: url, error: error)
        
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for complition")
        
        // Aquí queremos la respuesta con un error
        sut.get(from: url) { result in
            switch result {
                case let .failure(receiveError as NSError):
                    XCTAssertEqual(receiveError, error)
                default:
                    XCTFail("Expecte d failure with error \(error), got \(result) instead")
            }
            // Después de afirmar los valores podemos esperar la expectativa
            exp.fulfill()
        }
        
        // con un tiempo de espera
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private class URLSessionSpy: URLSession {
        // Necesitamos tener una colección de stubs
        // con una url que va a tener una tarea específica
        private var stubs = [URL: Stub]()
        
        private struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }
        
        func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            // El stub en una url dada, va a tener una task
            stubs[url] = Stub(task: task, error: error)
        }
        
        // Sobreescribimos esta función que se llamará en el método `get` ya que la clase que lo contien hereda de `URLSession`
        // y la clase `URLSessionHTTPClient` inyecta un `URLSessión` el cual recibe una `session` que es una instancia
        // de `URLSessionSpy` la cual también hereda de `URLSessión`, con lo que llamará a este método sobreescrito que devuelve
        // una `URLSessionDataTask` mockeada con la clase `FakeURLSessionDataTask` la cual evita las solicitudes a una `Network`
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            // El metodo devueve un `URLSessionDataTask` pero no queremos tener una solicitud de Network en
            // los test, por lo que tenemos que crear algún tipo de implementación mock para `URLSessionDataTask`
            // Cuando el código de producción solicita una `task`, devolvemos del `stub`, con una url dada, una
            // `task`, y si no la tiene, devolvemos una instancia de `FakeURLSessionDataTask`
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    // Mock para evitar devolver un `URLSessionDataTask`
    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
        
    }
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }
}

