//
//  FeedImageDataLoaderWithFallbackComposite.swift
//  EssentialApp
//
//  Created by Juan Carlos Merlos Albarracin on 1/9/23.
//

import Foundation
import EssentialFeed

public class FeedImageDataLoaderWithFallbackComposite: FeedImageDataLoader {
    private let primary: FeedImageDataLoader
    private let fallback: FeedImageDataLoader
    
    public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    private class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        let task = TaskWrapper()
        // Comenzamos a cargar la `ImageData` desde `primary` y mantenemos la referencia a la tarea `task`
        // Si cancelamos la operación en esta etapa, cancelamos los `loadImageData primary`
        task.wrapped = primary.loadImageData(from: url) { [weak self] result in
            // Por otra parte si tenemos éxito completamos con `Result`
            switch result {
                case .success:
                    completion(result)
                    
                    // Si falla, intentamos cargar los `loadImageData fallback` desde el alternativo
                case .failure:
                    // Aquí tenemos una referencia a la tarea de respaldo (`fallback`)
                    task.wrapped = self?.fallback.loadImageData(from: url, completion: completion)
                    // Si cancelamos durante un `fallback`, cancelamos el `fallback`
            }
            
        }
        return task
    }
}
