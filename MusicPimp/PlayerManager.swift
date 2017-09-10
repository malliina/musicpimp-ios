//
//  PlayerManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerManager: EndpointManager {
    let log = LoggerFactory.pimp("PlayerManager", category: "Pimp")
    
    static let sharedInstance = PlayerManager()
    let players = Players.sharedInstance
    
    fileprivate var activePlayer: PlayerType
    var active: PlayerType { get { return activePlayer } }
    let playerChanged = Event<PlayerType>()
    
    init() {
        let settings = PimpSettings.sharedInstance
        activePlayer = players.fromEndpoint(settings.activePlayer())
        super.init(key: PimpSettings.PLAYER, settings: settings)
    }
    
    func use(endpoint: Endpoint) -> PlayerType {
        activePlayer.close()
        let _ = saveActive(endpoint)
        let p = players.fromEndpoint(endpoint)
        activePlayer = p
        log.info("Player set to \(endpoint.name)")
        activePlayer.open(onOpened, onError: onError) // async
        playerChanged.raise(p)
        return p
    }
        
    func onOpened() {
        
    }
    
    func onError(_ error: Error) {
        
    }
}
