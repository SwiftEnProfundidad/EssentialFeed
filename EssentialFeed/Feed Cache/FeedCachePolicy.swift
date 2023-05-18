//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Juan Carlos Merlos Albarracin on 18/5/23.
//

import Foundation

// La hacemos `static` y la convertimos de `class` a `struct` ya que no requiere ni identidad ni estado
//internal struct FeedCachePolicy {

// `FeedCachePolicy` es un espacio de nombres, basta con una simple `class` de la que no se puede heredar.
// Es `internal` porque solo se usa dentro del módulo, pero la podemos hacer pública en algún momento
internal final class FeedCachePolicy {
    
    // La podemos hacer también una `enum` sin casos y no requiere un `init`
    // nunca puede instanciar ninguan representación de esta enum.
    //internal enum FeedCachePolicy {
    
    // Hacemos este `init` private para que nadie puede hacer una
    // instacia de ésta, ya que no necesita una identidad y no tiene estado.
    private init() {}
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    // Hacemos la función `static` ya que no tiene identidad y no necestiamos una instancia de `FeedCachePolicy`
    // Esta `policy` es detereminista, no tiene `side effets` y no tiene estado, es solo una regla.
    // Los objetos de valor son `Models` sin identidad. En este caso la `policy` no tiene identidad.
    // Encapsula una regla que se puede reutilizar, lo que significa que no necesitamos una instancia de ésta.
    
    // Interfaz abstracta
    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: 7, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
