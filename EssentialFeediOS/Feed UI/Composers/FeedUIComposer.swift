//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 21/8/23.
//

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let presenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(loadFeed: presenter.loadFeed)
        let feedController = FeedViewController(refreshController: refreshController)
        presenter.loadingView = WeakRefVirtualProxy(refreshController)
        presenter.feedView = FeedViewAdapter(controller: feedController, imageLoader: imageLoader)
        return feedController
    }
    
    // [FeedImage] transforma este array o -> Adapt -> en un array de [FeedImageCellController] -> (controller?.tableModel)
    // Este closure es un "Adapter pattern", muy común en los tipos `Composer`
    // Este patrón nos ayuda a conectar APIs inigualables como en este caso,
    // dado que `onRefresh` es un array de `FeedImage` y `tableModel` es un
    // array de `FeedImageCellController`
    private static func adaptFeedToCellControllers(forwardingTo controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.tableModel = feed.map { model in
                // Inyectamos un closure, `imageTransformer`, para transformar `ImageData` en `UIImage`
                FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: loader, imageTransformer: UIImage.init))
            }
        }
    }
}

// Este proxy virtual mantendrá una referencia `weak` a la
// instancia del objeto y pasará los mensajes hacia adelante
private final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

// Conformamos `WeakRefVirtualProxy` al protocolo `FeedLoadingView`
// y le decimos que el `object` va a ser de tipo `FeedLoadingView`
extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

// NOTA: con esto hacemos que el ciclo de retención ahora esté resuelto y la
// gestión de memoria vive en este `Composer`, lejos de los componentes MVP

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { model in
            // Inyectamos un closure, `imageTransformer`, para transformar `ImageData` en `UIImage`
            FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))
        }
    }
}
