//
//  StorageSize.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 29/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class StorageSize: CustomStringConvertible, Comparable {
    static let Zero = StorageSize(bytes: 0)
    static let k: Int = 1024
    static let k64 = Int64(StorageSize.k)
    
    let bytes: Int64
    
    init(bytes: Int64) {
        self.bytes = bytes
    }
    
    convenience init(kilos: Int) {
        self.init(bytes: Int64(kilos) * StorageSize.k64)
    }
    
    convenience init(megs: Int) {
        self.init(bytes: Int64(megs) * StorageSize.k64 * StorageSize.k64)
    }
    
    convenience init(gigs: Int) {
        self.init(bytes: Int64(gigs) * StorageSize.k64 * StorageSize.k64 * StorageSize.k64)
    }
    
    var toBytes: Int64 { return bytes }
    var toKilos: Int64 { return toBytes / StorageSize.k64 }
    var toMegs: Int64 { return toKilos / StorageSize.k64 }
    var toGigs: Int64 { return toMegs / StorageSize.k64 }
    var toTeras: Int64 { return toGigs / StorageSize.k64 }
    
    open var description: String {
        return shortDescription
    }
    
    var longDescription: String {
        return describe("bytes", kilos: "kilobytes", megas: "megabytes", gigas: "gigabytes", teras: "terabytes")
    }
    
    var shortDescription: String {
        return describe("B", kilos: "KB", megas: "MB", gigas: "GB", teras: "TB")
    }
    
    fileprivate func describe(_ bytes: String, kilos: String, megas: String, gigas: String, teras: String) -> String {
        if toTeras >= 10 { return "\(toTeras) \(teras)" }
        else if toGigs >= 10 { return "\(toGigs) \(gigas)" }
        else if toMegs >= 10 { return "\(toMegs) \(megas)" }
        else if toKilos >= 10 { return "\(toKilos) \(kilos)" }
        else { return "\(toBytes) \(bytes)" }
    }
    
    static func fromBytes(_ bytes: Int64) -> StorageSize? {
        return bytes >= 0 ? StorageSize(bytes: Int64(bytes)) : nil
    }
    
    static func fromBytes(_ bytes: Int) -> StorageSize? {
        return bytes >= 0 ? StorageSize(bytes: Int64(bytes)) : nil
    }
    
    static func fromKilos(_ kilos: Int) -> StorageSize? {
        return kilos >= 0 ? StorageSize(kilos: Int(kilos)) : nil
    }
    
    static func fromMegs(_ megs: Int) -> StorageSize? {
        return megs >= 0 ? StorageSize(megs: Int(megs)) : nil
    }
    
    static func fromGigas(_ gigs: Int) -> StorageSize? {
        return gigs >= 0 ? StorageSize(gigs: Int(gigs)) : nil
    }
}

public func ==(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes == rhs.bytes
}

public func <=(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes <= rhs.bytes
}

public func <(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes < rhs.bytes
}

public func >(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes > rhs.bytes
}

public func >=(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes >= rhs.bytes
}

func +(lhs: StorageSize, rhs: StorageSize) -> StorageSize {
    return StorageSize(bytes: lhs.bytes + rhs.bytes)
}

func -(lhs: StorageSize, rhs: StorageSize) -> StorageSize {
    return StorageSize(bytes: lhs.bytes - rhs.bytes)
}

public extension Int {
    var bytes: StorageSize? { get { return StorageSize.fromBytes(self) } }
    var kilos: StorageSize? { get { return StorageSize.fromKilos(self) } }
    var megs: StorageSize? { get { return StorageSize.fromMegs(self) } }
}
extension UInt64 {
    var bytes: StorageSize { get { return StorageSize(bytes: Int64(self)) } }
    var kilos: StorageSize { get { return StorageSize(bytes: Int64(Int64(self) * StorageSize.k64)) } }
    var megs: StorageSize { get { return StorageSize(bytes: Int64(Int64(self) * StorageSize.k64 * StorageSize.k64)) } }
}

