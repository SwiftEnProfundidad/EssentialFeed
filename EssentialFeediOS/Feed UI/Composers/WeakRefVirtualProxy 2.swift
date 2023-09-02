//
//  WeakRefVirtualProxy.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 28/8/23.
//

import UIKit
import EssentialFeed

// Este proxy virtual mantendrá una referencia `weak` a la
// instancia del objeto y pasará los mensajes hacia adelante
final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: FeedErrorView where T: FeedErrorView {
    func display(_ viewModel: FeedErrorViewModel) {
        object?.display(viewModel)
    }
}

// Conformamos `WeakRefVirtualProxy` al protocolo `FeedLoadingView`
// y le decimos que el `object` va a ser de tipo `FeedLoadingView`
extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ model: FeedImageViewModel<UIImage>) {
        object?.display(model)
    }
}
