//
//  RecentEntry.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/06/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

struct Recents: Codable {
    let recents: [RecentEntry]
}

struct RecentEntry: Codable, TopEntry {
    static let When = "when"
    
    let track: Track
    var entry: Track { return track }
    // milliseconds
    let when: UInt64
    
    var timestamp: Date { return Date(timeIntervalSince1970: Double(when) / 1000) }
}
