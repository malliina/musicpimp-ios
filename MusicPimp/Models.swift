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

class Track: MusicItem {
    let album: String
    let artist: String
    let duration: Duration
    let path: String
    let size: Int64
    let url: NSURL
    //let username: String
    //let password: String
    
    init(id: String, title: String, album: String, artist: String, duration: Duration, path: String, size: Int64, url: NSURL) {
        self.album = album
        self.artist = artist
        self.duration = duration
        self.path = path
        self.size = size
        self.url = url
        //self.username = username
        //self.password = password
        super.init(id: id, title: title)
    }
}

class MusicFolder {
    static let empty = MusicFolder(folder: Folder.empty, folders: [], tracks: [])
    
    let folder: Folder
    let folders: [Folder]
    let tracks: [Track]
    
    //var description: String = "Folder \(folder.title) with \(folders.count) subfolders and \(tracks.count) tracks"
    
    init(folder: Folder, folders: [Folder], tracks: [Track]) {
        self.folder = folder
        self.folders = folders
        self.tracks = tracks
    }
}

class Version {
    let version: String
    
    init(version: String) {
        self.version = version
    }
}
