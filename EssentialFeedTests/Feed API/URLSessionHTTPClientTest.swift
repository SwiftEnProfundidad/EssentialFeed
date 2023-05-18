//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/5/23.
//

import XCTest
import EssentialFeed

//// Creamos protocolos basados en mocking para burlarnos de la api de `URLSession`
////  y `URLSessionDataTask`. Esta la es la tercera forma para pruebas de network.
//
//// Lo que hacemos es hacer un protocolo que simule `URLSession` y para eso lo llamamos `HTTPSession`
//// Cambiamos `URL` --> `HTTP` y copiamos tal cual el método nativo de `URLSession`. El que implemente
//// este protocolo, ya no tendrá que sobreescribri (override) este método, solo tendrá que implementarlo,
//// ocultando así, todos los detalles internos sobre `URLSession`. Solo son abstracción para el testing.
//protocol HTTPSession {
//    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
//}
//
//// Hacemos lo mismo con `URLSessionDataTask` y la llamamos `HTTPSessionTask` y tiene el mismo
//// efecto que lo explicado en el protocolo anterior, pero solo copiamos el método `resume()`.
//// Sustituimos todas las `URLSession` por `HTTPSession` y todas las `URLSessionDataTask` por `HTTPSessionTask`
//protocol HTTPSessionTask {
//    func resume()
//}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Necesitamos registrear `URLProtocolStub`
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Una vez terminada la prueba tenemos que desregistrarla,
        // para no bloquear otras solicitudes de Test.
        URLProtocolStub.stopInterceptingRequests()
    }
    
    // Caso de uso de obtener la URL y realizar una solicitud GET con la URL.
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        // Creamos un método para observar las request y
        // comparamos que la url y el httpMethod sea iguales
        // a los que los dados. Es decir, garantizamos la URL
        // y el método HTTP correctos en la solicitud GET
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        // Hacemos la solicitud desde una url dada.
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // Caso de uso en el que esperamos que el error recibido sea el mismo que el error de la solicitud
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        
        XCTAssertEqual(receivedError?._domain, requestError._domain)
        XCTAssertEqual(receivedError?._code, requestError._code)
        XCTAssertNotNil(receivedError)
    }
    
    // Caso de uso en el que falla en todos los valores: data, urlResponse, Error (todos nil)
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    // Caso de uso en el que tenemos `Data`, una `HTTPURLResponse` y ningún `Error` (nil)
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        // Given
        let data = anyData()
        let response = anyHTTPURLResponse()
        
        // When
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)
                
        // Then
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    // Caso de uso en el que entrega datos y respuestas vacíos en una respuesta HTTP
    // exitosa con datos `nil` ya que el `URL LOADING SYSTEM` completa la solicitud
    // con un valor de datos vacíos no nulos (0 bytes) que es un caso válido
    // (por ejemplo, HTTP 204 sin respuesta de contenido)
    func test_getFromURL_succeedsWithEmptyOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)
                
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    // MARK: - Helpers
    
    // Factory method: Movemos la creación de `URLSessionHTTPClient`
    // (el sistema bajo prueba, o SUT) a un método `Factory` para
    // proteger nuestra prueba de cambios importantes.
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        
        switch result {
            case let .success(data, response):
                return (data, response)
            default:
                XCTFail("Expected succes, got \(result) instead", file: file, line: line)
                return nil
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        
        // Aquí queremos la respuesta con un error
        switch result {
            case let .failure(error):
                return error
            default:
                // Todos son nil, no hay manera de manejar o recuperarse de este error
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
                return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        
        var receivedResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            // Removemos el stub interceptado al terminar
            stub = nil
            requestObserver = nil
        }
        
        // Podemos ver `canInit` se llama como método de clase,
        // por lo que todavía no tenemos una instancia. La `URL
        // LOADING SYSTEM` instanciará nuestro `URLProtocolStub`
        // solo si podemos manejar la solicitud.
        override class func canInit(with request: URLRequest) -> Bool {
            // Interceptamos todas las solicitudes
            return true
        }
        
        // En este método comienza a cargar la request. El framework comienza a manejar la solicitud.
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        // Invocamos este método para decir que ahora
        // es el momento de que empice a cargar la URL
        override func startLoading() {
            // Con este método y esta implementación estamos seguros de que cada solicitud
            // finaliza antes de que regrese el método de prueba que usa `URLProtocolStub`.
            // Con lo que no tendremos ninguan solicitud de fondo, al mismo tiempo que otros
            // métodos de prueba.
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            // Comprobar si hay datos y si hay, se
            // los pasamos al `URL LOADING SYSTEM`
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            // Comprobamos si hay respuesta
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            // Comprobamos si hay un error
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            // Tenemos que llamar al cliente y decirle que hemos
            // terminado de cargar y, completamos sin valores
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // Aquí no hacemos nada, pero si no lo implementamos,
        // obtendremos un bloqueo en tiempo de ejecución.
        override func stopLoading() {}
    }
}
