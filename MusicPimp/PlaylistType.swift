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
    func add(_ track: Track) -> ErrorMessage?
    func add(_ tracks: [Track]) -> [ErrorMessage]
    func removeIndex(_ index: Int) -> ErrorMessage?
    func move(_ src: Int, dest: Int) -> ErrorMessage?
}
