//
//  RecentEntry.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/06/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

open class RecentEntry {
    static let When = "when"
    
    let track: Track
    let when: Date
    
    init(track: Track, when: Date) {
        self.track = track
        self.when = when
    }
}
