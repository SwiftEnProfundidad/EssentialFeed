//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/5/23.
//

import XCTest
import EssentialFeed

// Creamos protocolos basados en mocking para burlarnos de la api de `URLSession`
//  y `URLSessionDataTask`. Esta la es la tercera forma para pruebas de network.

// Lo que hacemos es hacer un protocolo que simule `URLSession` y para eso lo llamamos `HTTPSession`
// Cambiamos `URL` --> `HTTP` y copiamos tal cual el método nativo de `URLSession`. El que implemente
// este protocolo, ya no tendrá que sobreescribri (override) este método, solo tendrá que implementarlo,
// ocultando así, todos los detalles internos sobre `URLSession`. Solo son abstracción para el testing.
protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

// Hacemos lo mismo con `URLSessionDataTask` y la llamamos `HTTPSessionTask` y tiene el mismo
// efecto que lo explicado en el protocolo anterior, pero solo copiamos el método `resume()`.
// Sustituimos todas las `URLSession` por `HTTPSession` y todas las `URLSessionDataTask` por `HTTPSessionTask`
protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
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
    
    private class URLSessionSpy: HTTPSession {
        // Necesitamos tener una colección de stubs
        // con una url que va a tener una tarea específica
        private var stubs = [URL: Stub]()
        
        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }
        
        func stub(url: URL, task: HTTPSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {
            // El stub en una url dada, va a tener una task
            stubs[url] = Stub(task: task, error: error)
        }
        
        // Sobreescribimos esta función que se llamará en el método `get` ya que la clase que lo contien hereda de `HTTPSession`
        // y la clase `URLSessionHTTPClient` inyecta un `URLSessión` el cual recibe una `session` que es una instancia
        // de `URLSessionSpy` la cual también hereda de `URLSessión`, con lo que llamará a este método sobreescrito que devuelve
        // una `HTTPSessionTask` mockeada con la clase `FakeURLSessionDataTask` la cual evita las solicitudes a una `Network`
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            // El metodo devueve un `HTTPSessionTask` pero no queremos tener una solicitud de Network en
            // los test, por lo que tenemos que crear algún tipo de implementación mock para `HTTPSessionTask`
            // Cuando el código de producción solicita una `task`, devolvemos del `stub`, con una url dada, una
            // `task`, y si no la tiene, devolvemos una instancia de `FakeURLSessionDataTask`
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    // Mock para evitar devolver un `HTTPSessionTask`
    private class FakeURLSessionDataTask: HTTPSessionTask {
        func resume() {}
        
    }
    private class URLSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}

