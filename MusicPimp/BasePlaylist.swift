//
//  BasePlaylist.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

// Intentionally does not implement PlaylistType because Swift sucks, but PlaylistType implementations 
// can still extend this for convenience
class BasePlaylist {
    let indexSubject = PublishSubject<Int?>()
    var indexEvent: Observable<Int?> { return indexSubject }
    
    let playlistSubject = PublishSubject<Playlist>()
    var playlistEvent: Observable<Playlist> { return playlistSubject }
    
    let trackSubject = PublishSubject<Track>()
    var trackAdded: Observable<Track> { return trackSubject}
}
