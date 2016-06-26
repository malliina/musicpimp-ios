//
//  PopularEntry.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/06/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

public class PopularEntry {
    let track: Track
    let playbackCount: Int
    
    init(track: Track, playbackCount: Int) {
        self.track = track
        self.playbackCount = playbackCount
    }
}
