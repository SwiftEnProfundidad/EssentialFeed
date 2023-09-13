//
//  FeedViewAdapter.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 28/8/23.
//

import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: (URL) -> FeedImageDataLoader.Publisher
    
    init(controller: FeedViewController, imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        // [FeedImage] transforma este array o -> Adapt -> en un array de [FeedImageCellController] -> (controller?.tableModel)
        // Este closure es un "Adapter pattern", muy común en los tipos `Composer`
        // Este patrón nos ayuda a conectar APIs inigualables como en este caso,
        // dado que `onRefresh` es un array de `FeedImage` y `tableModel` es un
        // array de `FeedImageCellController`
        controller?.display(viewModel.feed.map { model in
            let adapter = FeedImageDataLoaderPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(model: model, imageLoader: imageLoader)
            let view = FeedImageCellController(delegate: adapter)
            
            adapter.presenter = FeedImagePresenter(
                view: WeakRefVirtualProxy(view),
                imageTransformer: UIImage.init)
            
            return view
        })
    }
}
