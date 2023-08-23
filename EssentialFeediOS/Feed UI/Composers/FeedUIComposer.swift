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
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: feedViewModel)
        let feedController = FeedViewController(refreshController: refreshController)
        feedViewModel.onFeedLoad = adaptFeedToCellControllers(forwardingTo: feedController, loader: imageLoader)
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
