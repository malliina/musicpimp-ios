//
//  Playlist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
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
