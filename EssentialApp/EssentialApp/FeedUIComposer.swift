//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Juan Carlos Merlos Albarracin on 21/8/23.
//

import UIKit
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        // Aquí el `decoratee` está añadiendo comportamiento a la instancia sin cambiar la instancia -> Principio OpenClose
        // Mediante esta técnica hacemos que el `Presentet` sea agnóstico sobre Threading y la UI también es agnóstica y las
        // implementaciones de `FeedLoader` no saben que las implementaciones de UIKit requieren trabajo para ser enviadas a `MainQueue
        // Todavía mantenemos nuestras implementaciones desacopladas sin filtrar ningún detalle sobre los tipos concretos.
        // La capa `Composer` es responsable de ordenar o componer los objetos.
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader))
        
        let feedController = makeFeedViewController(
            delegate: presentationAdapter,
            title: FeedPresenter.title)
        
        presentationAdapter.presenter = FeedPresenter(
            feedView: FeedViewAdapter(
                controller: feedController,
                imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader)),
            loadingView: WeakRefVirtualProxy(feedController),
            errorView: WeakRefVirtualProxy(feedController))
        
        return feedController
    }
    
    private static func makeFeedViewController(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.delegate = delegate
        feedController.title = title
        return feedController
    }
}

// NOTA: con esto hacemos que el ciclo de retención ahora esté resuelto y la
// gestión de memoria vive en este `Composer`, lejos de los componentes MVP
