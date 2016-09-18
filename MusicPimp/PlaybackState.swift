//
//  PlayerState.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

enum PlaybackState: String {
    case Playing = "Playing"
    case Paused = "Paused"
    case Stopped = "Stopped"
    case NoMedia = "NoMedia"
    case Unknown = "Unknown"
    
    static func fromName(_ name: String) -> PlaybackState? {
        if let state = PlaybackState(rawValue: name) {
            return state
        } else {
            // legacy compatibility
            switch name {
            case "Closed":
                return .Stopped
            case "Open":
                return .Paused
            case "Started":
                return .Playing
            default:
                return nil
            }
        }
    }
}
