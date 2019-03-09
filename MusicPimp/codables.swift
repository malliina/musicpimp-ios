//
//  codables.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/03/2019.
//  Copyright © 2019 Skogberg Labs. All rights reserved.
//

import Foundation

protocol IdCodable: Codable, CustomStringConvertible {
    init(id: String)
    var value: String { get }
}

extension IdCodable {
    var description: String { return value }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(id: raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

protocol IntCodable: Codable {
    init(value: Int)
    var value: Int { get }
}

extension IntCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        self.init(value: raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

protocol LargeIntCodable: Codable {
    init(value: Int64)
    var value: Int64 { get }
}

extension LargeIntCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int64.self)
        self.init(value: raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}


