//
//  XCTestCase+Snapshot.swift
//  EssentialFeediOSTests
//
//  Created by Juan Carlos Merlos Albarracin on 7/9/23.
//

import XCTest

extension XCTestCase {
    
    func assert(snapshot: UIImage, named name: String, file: StaticString = #file, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            XCTFail("Failed to load stored snapshot at URL: \(snapshotURL). Use the `record` method to store a snapshot before asserting.", file: file, line: line)
            return
        }
        
        // Comparamos si los nuevos datos de la `snapshot` coinciden con los almacenados
        if snapshotData != storedSnapshotData {
            // Si no lo hacen, creamos una url temporal donde escribir los nuevos datos de snapshot
            let temporarySnapshotURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(snapshotURL.lastPathComponent)
            
            // Entonces podemos comparar visualmente con el otro
            try? snapshotData?.write(to: temporarySnapshotURL)
            
            // Si no coinciden, lanzamos un error
            XCTFail("New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL), Stored snapshot URL: \(snapshotURL)", file: file, line: line)
        }
    }
    
    func record(snapshot: UIImage, named name: String, file: StaticString = #file, line: UInt = #line) {
        let snapshotURL = makeSnapshotURL(named: name, file: file)
        let snapshotData = makeSnapshotData(for: snapshot, file: file, line: line)
        
        // Nos aseguramos de que esta estructura de carpetas exista en el sistema de `File`
        // para que podamos usar `FileManager` para crear la carpeta si es necesario.
        do {
            try FileManager.default.createDirectory(
                at: snapshotURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            // Guardamos los datos de snapshot
            try snapshotData?.write(to: snapshotURL)
        } catch {
            // Si puede crearla, obtenemos un error de aserción
            XCTFail("Failed to record snapshot with error: \(error)", file: file, line: line)
        }
    }
    
    private func makeSnapshotURL(named name: String, file: StaticString) -> URL {
        // Creamos un `filePath` para crear la URL ya que el parámetro
        // `file` contiene la ruta al file actual (`FeedSnapshotTest.swift`)
        // Idealmente, deberíamos almacenar las instantaneas cerca del file de prueba.
        // Estas se almacenarán en git para que otros puedan validarlas.
        // `../EssentialFeedIOSTest/FeedSnapshotTest.swift` -> ruta almacenaje.
        return URL(fileURLWithPath: String(describing: file))
        // Borramos la última ruta
            .deletingLastPathComponent()
        // Añadimos un componente de ruta para crear una nueva estructura de carpetas para las snapshots
        // `../EssentialFeedIOSTest/snapshots` -> ruta almacenaje.
            .appendingPathComponent("snapshots")
        // y le añadimos el nombre a la ruta, `../EssentialFeedIOSTest/snapshots/EMPTY_FEED.png` -> ruta almacenaje.
            .appendingPathComponent("\(name).png")
    }
    
    private func makeSnapshotData(for snapshot: UIImage, file: StaticString, line: UInt) -> Data? {
        guard let data = snapshot.pngData() else {
            XCTFail("Failed to generate PNG data representation from snapshot", file: file, line: line)
            return nil
        }
        
        return data
    }
    
}
