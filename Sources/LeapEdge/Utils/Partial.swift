//
//  Partial.swift
//  
//
//  Created by Rishi Serumadar on 09/09/2022.
//

import Foundation

public struct Partial<Wrapped> {
    private var values: [PartialKeyPath<Wrapped>: Any] = [:]

    subscript<ValueType>(key: KeyPath<Wrapped, ValueType>) -> ValueType? {
        get {
            return values[key] as? ValueType
        }
        set {
            values[key] = newValue
        }
    }
}
