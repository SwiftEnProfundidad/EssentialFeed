//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 3/5/23.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    /// The completion handler can be invoked in any trhead.
    /// Clients are responsible to dispatch to appropriate trheads, if needed.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
