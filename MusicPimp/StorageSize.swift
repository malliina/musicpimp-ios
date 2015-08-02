//
//  StorageSize.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 29/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class StorageSize: Printable, Comparable {
    static let Zero = StorageSize(bytes: 0)
    static let k: UInt = 1024
    static let k64: UInt64 = UInt64(StorageSize.k)
    
    let bytes: UInt64
    
    init(bytes: UInt64) {
        self.bytes = bytes
    }
    convenience init(kilos: UInt) {
        self.init(bytes: UInt64(kilos * StorageSize.k))
    }
    convenience init(megs: UInt) {
        self.init(kilos: UInt(megs * StorageSize.k))
    }
    convenience init(gigs: UInt) {
        self.init(megs: UInt(gigs * StorageSize.k))
    }
    
    var toBytes: UInt64 { return bytes }
    var toKilos: UInt64 { return toBytes / StorageSize.k64 }
    var toMegs: UInt64 { return toKilos / StorageSize.k64 }
    var toGigs: UInt64 { return toMegs / StorageSize.k64 }
    var toTeras: UInt64 { return toGigs / StorageSize.k64 }
    
    var description: String {
        if toTeras > 10 { return "\(toTeras) terabytes" }
        else if toGigs > 10 { return "\(toGigs) gigabytes" }
        else if toMegs > 10 { return "\(toMegs) megabytes" }
        else if toKilos > 10 { return "\(toKilos) kilobytes" }
        else { return "\(toBytes) bytes" }
    }
    
    static func fromBytes(bytes: Int64) -> StorageSize? {
        return bytes >= 0 ? StorageSize(bytes: UInt64(bytes)) : nil
    }
    static func fromBytes(bytes: Int) -> StorageSize? {
        return bytes >= 0 ? StorageSize(bytes: UInt64(bytes)) : nil
    }
    static func fromKilos(kilos: Int) -> StorageSize? {
        return kilos >= 0 ? StorageSize(kilos: UInt(kilos)) : nil
    }
    static func fromMegs(megs: Int) -> StorageSize? {
        return megs >= 0 ? StorageSize(megs: UInt(megs)) : nil
    }
    static func fromGigas(gigs: Int) -> StorageSize? {
        return gigs >= 0 ? StorageSize(gigs: UInt(gigs)) : nil
    }
}

func ==(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes == rhs.bytes
}
func <=(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes <= rhs.bytes
}
func <(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes < rhs.bytes
}
func >(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes > rhs.bytes
}
func >=(lhs: StorageSize, rhs: StorageSize) -> Bool {
    return lhs.bytes >= rhs.bytes
}
func +(lhs: StorageSize, rhs: StorageSize) -> StorageSize {
    return StorageSize(bytes: lhs.bytes + rhs.bytes)
}

extension Int {
    var bytes: StorageSize? { get { return StorageSize.fromBytes(self) } }
    var kilos: StorageSize? { get { return StorageSize.fromKilos(self) } }
    var megs: StorageSize? { get { return StorageSize.fromMegs(self) } }
}
extension UInt64 {
    var bytes: StorageSize { get { return StorageSize(bytes: self) } }
    var kilos: StorageSize { get { return StorageSize(bytes: self * StorageSize.k64) } }
    var megs: StorageSize { get { return StorageSize(bytes: self * StorageSize.k64 * StorageSize.k64) } }
}

