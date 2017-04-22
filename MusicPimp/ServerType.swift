//
//  ServerType.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 05/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public struct ServerType {
    let name: String
    let index: Int
    var isCloud: Bool { get { return name == ServerTypes.Cloud.name } }
}

class ServerTypes {
    static let Cloud = ServerType(name: "Cloud", index: 0)
    static let MusicPimp = ServerType(name: "MusicPimp", index: 1)
    static let Subsonic = ServerType(name: "Subsonic", index: 2)
    static let Local = ServerType(name: "Local", index: 3)
    
    static let All = [Cloud, MusicPimp, Subsonic]
    
    static func fromIndex(_ i: Int) -> ServerType? {
        return All.find({ $0.index == i })
    }
    static func fromName(_ name: String) -> ServerType? {
        return All.find({ $0.name == name })
    }
}


extension ServerType: Equatable {}

public func ==(lhs: ServerType, rhs: ServerType) -> Bool {
    return lhs.name == rhs.name
}
