//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Juan Carlos Merlos Albarracin on 17/5/23.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
