//
//  ListeningController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 06/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class ListeningController: PimpViewController {
    var loadedListeners: [Disposable] = []
    var appearedListeners: [Disposable] = []
    
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var player: PlayerType { return playerManager.active }
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var library: LibraryType { return libraryManager.active }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.playerChanged.addHandler(self) { (pc) -> (PlayerType) -> () in
            pc.onNewPlayer
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenWhenAppeared(player)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unlistenWhenAppeared()
    }
    
    func updateTrack(_ track: Track?) {
        if let track = track {
            updateMedia(track)
        } else {
            updateNoMedia()
        }
    }
    
    func updateMedia(_ track: Track) {
        
    }
    
    func updateNoMedia() {
        
    }
    
    func onTimeUpdated(_ position: Duration) {
        
    }
    
    func onStateChanged(_ state: PlaybackState) {
        
    }
    
    func onNewPlayer(_ newPlayer: PlayerType) {
        reinstallListeners(newPlayer)
    }
    
    func listenWhenLoaded(_ targetPlayer: PlayerType) {
        let trackListener = targetPlayer.trackEvent.addHandler(self) { (pc) -> (Track?) -> () in
            pc.updateTrack
        }
        loadedListeners = [trackListener]
    }
    
    func unlistenWhenLoaded() {
        for listener in loadedListeners {
            listener.dispose()
        }
        loadedListeners = []
    }
    
    func listenWhenAppeared(_ targetPlayer: PlayerType) {
        unlistenWhenAppeared()
        let listener = targetPlayer.timeEvent.addHandler(self) { (pc) -> (Duration) -> () in
            pc.onTimeUpdated
        }
        let stateListener = targetPlayer.stateEvent.addHandler(self) { (pc) -> (PlaybackState) -> () in
            pc.onStateChanged
        }
        appearedListeners = [listener, stateListener]
//        Log.info("Installed state listener")
    }
    
    func unlistenWhenAppeared() {
        for listener in appearedListeners {
            listener.dispose()
        }
        appearedListeners = []
//        Log.info("Uninstalled state listeners")
    }
    
    fileprivate func reinstallListeners(_ targetPlayer: PlayerType) {
        unlistenWhenAppeared()
        unlistenWhenLoaded()
        listenWhenLoaded(targetPlayer)
        listenWhenAppeared(targetPlayer)
    }

}
