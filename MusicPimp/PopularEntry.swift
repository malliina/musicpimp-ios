//
//  PopularEntry.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/06/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

protocol TopEntry {
    var entry: Track { get }
}

struct Populars: Codable {
    let populars: [PopularEntry]
}

struct PopularEntry: Codable, TopEntry {
    let track: Track
    var entry: Track { return track }
    let playbackCount: Int
}
