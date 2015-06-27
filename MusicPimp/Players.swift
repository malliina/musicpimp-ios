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
        let serverType = e.serverType
        switch serverType.name {
        case ServerTypes.MusicPimp.name:
            return PimpPlayer(e: e)
        case ServerTypes.Cloud.name:
            return PimpPlayer(e: e)
        default:
            return LocalPlayer.sharedInstance
        }
    }
}
