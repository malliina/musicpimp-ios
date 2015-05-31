//
//  PlayerManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class PlayerManager: EndpointManager {
    static let sharedInstance = PlayerManager()
    
    private var activePlayer: PlayerType
    var active: PlayerType { get { return activePlayer } }
    let playerChanged = Event<PlayerType>()
    
    init() {
        var settings = PimpSettings.sharedInstance
        activePlayer = Players.fromEndpoint(settings.activeEndpoint(PimpSettings.PLAYER))
        super.init(key: PimpSettings.PLAYER, settings: settings)
        changed.addHandler(self, handler: { (lm) -> Endpoint -> () in
            lm.onNewPlayerEndpoint
        })
        activePlayer.open()
    }
    static func toURL(s:String) -> NSURL {
        return NSURL(string: s)!
    }
    private func onNewPlayerEndpoint(endpoint: Endpoint) {
        activePlayer.close()
        let p = Players.fromEndpoint(endpoint)
        activePlayer = p
        activePlayer.open() // async
        playerChanged.raise(p)
    }
}
