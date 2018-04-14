//
//  PlayerManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerManager: EndpointManager {
    let log = LoggerFactory.shared.pimp(PlayerManager.self)
    
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
    
    func use(endpoint: Endpoint) {
        use(endpoint: endpoint) { _ in () }
    }
    
    func use(endpoint: Endpoint, onOpen: @escaping (PlayerType) -> Void) {
        activePlayer.close()
        let _ = saveActive(endpoint)
        let p = players.fromEndpoint(endpoint)
        activePlayer = p
        log.info("Player set to \(endpoint.name)")
        // async
        activePlayer.open(onError: onError) { 
            self.onOpened(p)
            onOpen(p)
        }
        playerChanged.raise(p)
    }

    func onOpened(_ player: PlayerType) {
        
    }
    
    func onError(_ error: Error) {
        log.error("Player error \(error)")
    }
}
