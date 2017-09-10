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
    
    fileprivate var activePlayer: PlayerType
    var active: PlayerType { get { return activePlayer } }
    let playerChanged = Event<PlayerType>()
    var disposable: Disposable? = nil
    
    init() {
        let settings = PimpSettings.sharedInstance
        activePlayer = Players.fromEndpoint(settings.activeEndpoint(PimpSettings.PLAYER))
        super.init(key: PimpSettings.PLAYER, settings: settings)
        disposable = changed.addHandler(self) { (lm) -> (Endpoint) -> () in
            lm.onNewPlayerEndpoint
        }
        // not called here, because it's instead called in AppDelegate.application(... didFinishLaunchingWithOptions ...)
        // activePlayer.open()
    }
    
    fileprivate func onNewPlayerEndpoint(_ endpoint: Endpoint) {
        activePlayer.close()
        let p = Players.fromEndpoint(endpoint)
        activePlayer = p
        log.info("Set player to \(endpoint.name) \(p.isLocal)")
        activePlayer.open(onOpened, onError: onError) // async
        playerChanged.raise(p)
    }
    
    func onOpened() {
        
    }
    
    func onError(_ error: Error) {
        
    }
}
