//
//  PlayerInfo.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import AVFoundation

class PlayerInfo {
    let player: AVPlayer
    let track: Track
    
    init(player: AVPlayer, track: Track) {
        self.player = player
        self.track = track
    }
}
