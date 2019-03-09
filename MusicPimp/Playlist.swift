//
//  Playlist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

struct Playlist {
    static let empty = Playlist(tracks: [], index: nil)
    
    let tracks: [Track]
    let index: Int?
}
