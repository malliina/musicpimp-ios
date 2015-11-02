//
//  MusicFolder.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

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
