//
//  models.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/03/2019.
//  Copyright © 2019 Skogberg Labs. All rights reserved.
//

import Foundation


struct AlarmID: Hashable, IdCodable {
    let id: String
    var value: String { return id }
}

struct TrackID: Hashable, IdCodable {
    let id: String
    var value: String { return id }
}

struct FolderID: Hashable, IdCodable {
    let id: String
    var value: String { return id }
    static func empty() -> FolderID { return FolderID(id: "") }
}

struct Version: Codable {
    let version: String
}

struct VolumeValue: IntCodable {
    static let Min = VolumeValue(volume: 0)
    static let Max = VolumeValue(volume: 100)
    static let Default = VolumeValue(volume: 40)
    
    let volume: Int
    var value: Int { return volume }
    
    init(volume: Int) {
        self.volume = volume
    }
    
    init(value: Int) {
        self.volume = value
    }
    
    init(volumeFloat: Float) {
        self.volume = Int(volumeFloat * 100)
    }
    
    func toFloat() -> Float {
        return Float(1.0 * Float(volume) / 100.0)
    }
}


struct PushToken: IdCodable, Equatable {
    static let noToken = PushToken(token: PimpSettings.NoPushTokenValue)
    let token: String
    var value: String { return token }
    
    init(token: String) {
        self.token = token
    }
    
    init(id: String) {
        self.token = id
    }
    
    public static func ==(lhs: PushToken, rhs: PushToken) -> Bool { return lhs.token == rhs.token }
}


struct PlaylistIdResponse: Codable {
    let id: PlaylistID
}

struct PlaylistID: IntCodable, CustomStringConvertible {
    let id: Int
    var value: Int { return id }
    
    init(id: Int) {
        self.id = id
    }
    
    init(value: Int) {
        self.id = value
    }
    
    var description: String { return "\(id)" }
}

struct Playlist {
    static let empty = Playlist(tracks: [], index: nil)
    
    let tracks: [Track]
    let index: Int?
}


protocol MusicItem {
    var idStr: String { get }
    var title: String { get }
}

struct Track: MusicItem, Codable {
    static let empty = Track(id: TrackID(id: ""), title: "", album: "", artist: "", duration: Duration.Zero, path: "", size: StorageSize.Zero, url: URL(string: "https://www.musicpimp.org")!)
    let id: TrackID
    let title: String
    let album: String
    let artist: String
    let duration: Duration
    let path: String
    let size: StorageSize
    let url: URL
    var idStr: String { return id.id }
    
    public static func ==(lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Folder: Codable, MusicItem {
    static let empty = Folder(id: FolderID.empty(), title: "", path: "")
    static let root = empty
    
    let id: FolderID
    let title: String
    let path: String
    // The API also returns a URL
    //    let url: URL
    
    var idStr: String { return id.id }
}

struct MusicFolder: Codable {
    static let empty = MusicFolder(folder: Folder.empty, folders: [], tracks: [])
    
    let folder: Folder
    let folders: [Folder]
    let tracks: [Track]
    
    var items: [MusicItem] {
        // type inference hack
        let fs: [MusicItem] = folders
        let ts: [MusicItem] = tracks
        return fs + ts
    }
}
