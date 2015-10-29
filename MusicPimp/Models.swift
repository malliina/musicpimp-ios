//
//  Models.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Playlist {
    static let empty = Playlist(tracks: [], index: nil)
    
    let tracks: [Track]
    let index: Int?
    init(tracks: [Track], index: Int?) {
        self.tracks = tracks
        self.index = index
    }
    
}
class MusicItem {
    let id: String
    let title: String
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

class Folder: MusicItem {
    static let empty = Folder(id: "", title: "", path: "")
    static let root = empty
    
    let path: String
    
    init(id: String, title: String, path: String) {
        self.path = path
        super.init(id: id, title: title)
    }
}

class Track: MusicItem, Hashable {
    let album: String
    let artist: String
    let duration: Duration
    let path: String
    let size: StorageSize
    let url: NSURL
    
    var hashValue : Int { get { return self.id.hashValue } }
    
    init(id: String, title: String, album: String, artist: String, duration: Duration, path: String, size: StorageSize, url: NSURL) {
        self.album = album
        self.artist = artist
        self.duration = duration
        self.path = path
        self.size = size
        self.url = url
        super.init(id: id, title: title)
    }
}

func ==(lhs: Track, rhs: Track) -> Bool {
    return lhs.id == rhs.id
}

class MusicFolder {
    static let empty = MusicFolder(folder: Folder.empty, folders: [], tracks: [])
    
    let folder: Folder
    let folders: [Folder]
    let tracks: [Track]
    let items: [MusicItem]
    
    //var description: String = "Folder \(folder.title) with \(folders.count) subfolders and \(tracks.count) tracks"
    
    init(folder: Folder, folders: [Folder], tracks: [Track]) {
        self.folder = folder
        self.folders = folders
        self.tracks = tracks
        // folders + tracks doesn't work
        let foldersAsItems: [MusicItem] = folders
        let tracksAsItems: [MusicItem] = tracks
        items = foldersAsItems + tracksAsItems
    }
}

class Version {
    let version: String
    
    init(version: String) {
        self.version = version
    }
}

class SavedPlaylist {
    let id: String?
    let name: String
    let tracks: [Track]
    
    init(id: String?, name: String, tracks: [Track]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
