//
//  RecentEntry.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/06/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

public class RecentEntry {
    let track: Track
    let when: NSDate
    
    init(track: Track, when: NSDate) {
        self.track = track
        self.when = when
    }
}
