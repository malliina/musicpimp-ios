//
//  Players.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 19/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class Players {
    static func fromEndpoint(e: Endpoint) -> PlayerType {
        if e.id == Endpoint.Local.id {
            return LocalPlayer.sharedInstance
        } else {
            switch e.serverType {
            case .MusicPimp:
                return PimpPlayer(e: e)
            default:
                return LocalPlayer.sharedInstance
            }
        }
    }
}
