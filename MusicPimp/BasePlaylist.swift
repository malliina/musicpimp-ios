//
//  BasePlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
// Intentionally does not implement PlaylistType because Swift sucks, but PlaylistType implementations 
// can still extend this for convenience
class BasePlaylist {
    let indexEvent = Event<Int?>()
    let playlistEvent = Event<Playlist>()
    let trackAdded = Event<Track>()
}
