//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 3/5/23.
//

import Foundation

// Creamos esta enum para evitar tener casos de más y que no están reflejados
// en nuestro contrato y evitar los opcionales como podría ser tener `HTTPURLResponse`
// y `Error` de tipo opcional, ya que de ser así, tendríamos cuatro casos, `HTTPURLResponse`
// que podría traer `nil` o un valor y `Error` también `nil` o valor, con lo que serían cuatro casos.
// Con esta enum, solo tenemos dos casos, un `success` o un `failure` y sin opcionales, eliminando así dos estados inválidos.
public enum HTTPClientResult {
    // en caso de `success` tendremos los datos y la respuesta (200...)
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

//public typealias HTTPClientResult = (Result<(Data, HTTPURLResponse), Error>)

public protocol HTTPClient {
    /// The completion handler can be invoked in any trhead.
    /// Clients are responsible to dispatch to appropriate trheads, if needed.
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
