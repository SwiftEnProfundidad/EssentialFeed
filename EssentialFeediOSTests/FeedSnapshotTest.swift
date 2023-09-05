//
//  FeedSnapshotTest.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/9/23.
//

import XCTest
import EssentialFeediOS
@testable import EssentialFeed

class FeedSnapshotTest: XCTestCase {
    
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        record(snapshot: sut.snapshot(), named: "EMPTY_FEED")
    }
    
    func test_feedWithContent() {
        let sut = makeSUT()
        
        sut.display(feedWithContent())
        
        record(snapshot: sut.snapshot(), named: "FEED_WITH_CONTENT")
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! FeedViewController
        controller.loadViewIfNeeded()
        return controller
    }
    
    private func emptyFeed() -> [FeedImageCellController] {
        return []
    }
    
    private func feedWithContent() -> [ImageStub] {
        return [
            ImageStub(
                description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                location: "East Side Gallery\nMemorial in Berlin, Germany",
                image: UIImage.make(withColor: .red)
            ),
            ImageStub(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales.",
                location: "Garth Pier",
                image: UIImage.make(withColor: .green)
            )
        ]
    }
    
    private func record(snapshot: UIImage, named name: String, file: StaticString = #file, line: UInt = #line) {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail("Failed to generate PNG data representation from snapshot", file: file, line: line)
            return
        }
        
        // Creamos un `filePath` para crear la URL ya que el parámetro
        // `file` contiene la ruta al file actual (`FeedSnapshotTest.swift`)
        // Idealmente, deberíamos almacenar las instantaneas cerca del file de prueba.
        // Estas se almacenarán en git para que otros puedan validarlas.
        // `../EssentialFeedIOSTest/FeedSnapshotTest.swift` -> ruta almacenaje.
        let snapshotURL = URL(fileURLWithPath: String(describing: file))
        // Borramos la última ruta
            .deletingLastPathComponent()
        // Añadimos un componente de ruta para crear una nueva estructura de carpetas para las snapshots
        // `../EssentialFeedIOSTest/snapshots` -> ruta almacenaje.
            .appendingPathComponent("snapshots")
        // y le añadimos el nombre a la ruta, `../EssentialFeedIOSTest/snapshots/EMPTY_FEED.png` -> ruta almacenaje.
            .appendingPathComponent("\(name).png")
        
        // Nos aseguramos de que esta estructura de carpetas exista en el sistema de `File`
        // para que podamos usar `FileManager` para crear la carpeta si es necesario.
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            // Guardamos los datos de snapshot
            try snapshotData.write(to: snapshotURL)
        } catch {
            // Si puede crearla, obtenemos un error de aserción
            XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }
}

extension UIViewController {
    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { action in
            view.layer.render(in: action.cgContext)
        }
    }
}

// Convertimos `ImageStubs` en `ImageCellControllers
private extension FeedViewController {
    func display(_ stubs: [ImageStub]) {
        let cells: [FeedImageCellController] = stubs.map { stub in
            let cellController = FeedImageCellController(delegate: stub)
            stub.controller = cellController
            return cellController
        }
        
        display(cells)
    }
}

private class ImageStub: FeedImageCellControllerDelegate {
    let viewModel: FeedImageViewModel<UIImage>
    weak var controller: FeedImageCellController?
    
    init(description: String?, location: String?, image: UIImage?) {
        viewModel = FeedImageViewModel(
            description: description,
            location: location,
            image: image,
            isLoading: false,
            shouldRetry: image == nil)
    }
    
    func didRequestImage() {
        controller?.display(viewModel)
    }
    
    func didCancelImageRequest() {}
}