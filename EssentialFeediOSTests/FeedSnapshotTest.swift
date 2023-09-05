//
//  FeedSnapshotTest.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 4/9/23.
//

import XCTest
import EssentialFeediOS

class FeedSnapshotTest: XCTestCase {
    
    func test_emptyFeed() {
        let sut = makeSUT()
        
        sut.display(emptyFeed())
        
        record(snapshot: sut.snapshot(), named: "EMPTY_FEED")
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
