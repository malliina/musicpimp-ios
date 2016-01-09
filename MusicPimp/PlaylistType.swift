//
//  PlaylistType.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
protocol PlaylistType {
    var indexEvent: Event<Int?> { get }
    var playlistEvent: Event<Playlist> { get }
    var trackAdded: Event<Track> { get }
    func add(track: Track)
    func add(tracks: [Track])
    func removeIndex(index: Int)
    func move(src: Int, dest: Int)
}
