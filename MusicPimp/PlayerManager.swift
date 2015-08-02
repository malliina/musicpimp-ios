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
        //Log.info("Init PlayerManager")
        var settings = PimpSettings.sharedInstance
        activePlayer = Players.fromEndpoint(settings.activeEndpoint(PimpSettings.PLAYER))
        super.init(key: PimpSettings.PLAYER, settings: settings)
        changed.addHandler(self, handler: { (lm) -> Endpoint -> () in
            lm.onNewPlayerEndpoint
        })
        // not called here, because it's instead called in AppDelegate.application(... didFinishLaunchingWithOptions ...)
        // activePlayer.open()
    }
    private func onNewPlayerEndpoint(endpoint: Endpoint) {
        activePlayer.close()
        let p = Players.fromEndpoint(endpoint)
        activePlayer = p
        Log.info("Set player to \(endpoint.name) \(p.isLocal)")
        activePlayer.open() // async
        playerChanged.raise(p)
    }
}
