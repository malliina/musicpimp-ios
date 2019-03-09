//
//  ServerType.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 05/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

enum ServerType: String, Codable {
    case cloud = "Cloud"
    case musicPimp = "MusicPimp"
    case subsonic = "Subsonic"
    case local = "Local"

    var isCloud: Bool { get { return name == ServerType.cloud.name } }
    
    var name: String { switch self {
        case .cloud: return "Cloud"
        case .musicPimp: return "MusicPimp"
        case .subsonic: return "Subsonic"
        case .local: return "Local"
    }}
    
    var index: Int { switch self {
        case .cloud: return 0
        case .musicPimp: return 1
        case .subsonic: return 2
        case .local: return 3
    }}
}

class ServerTypes {
    static let all: [ServerType] = [.cloud, .musicPimp, .subsonic]
    
    static func fromIndex(_ i: Int) -> ServerType? {
        return all.find { $0.index == i }
    }
    static func fromName(_ name: String) -> ServerType? {
        return all.find { $0.name == name }
    }
}
