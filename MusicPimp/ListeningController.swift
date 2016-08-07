//
//  ListeningController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 06/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class ListeningController: UIViewController {
    var loadedListeners: [Disposable] = []
    var appearedListeners: [Disposable] = []
    
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var player: PlayerType { return playerManager.active }
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var library: LibraryType { return libraryManager.active }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerManager.playerChanged.addHandler(self, handler: { (pc) -> PlayerType -> () in
            pc.onNewPlayer
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listenWhenAppeared(player)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        unlistenWhenAppeared()
    }
    
    func updateTrack(track: Track?) {
        if let track = track {
            updateMedia(track)
        } else {
            updateNoMedia()
        }
    }
    
    func updateMedia(track: Track) {
        
    }
    
    func updateNoMedia() {
        
    }
    
    func onTimeUpdated(position: Duration) {
        
    }
    
    func onStateChanged(state: PlaybackState) {
        
    }
    
    func onNewPlayer(newPlayer: PlayerType) {
        reinstallListeners(newPlayer)
    }
    
    func listenWhenLoaded(targetPlayer: PlayerType) {
        let trackListener = targetPlayer.trackEvent.addHandler(self, handler: { (pc) -> Track? -> () in
            pc.updateTrack
        })
        loadedListeners = [trackListener]
    }
    
    func unlistenWhenLoaded() {
        for listener in loadedListeners {
            listener.dispose()
        }
        loadedListeners = []
    }
    
    func listenWhenAppeared(targetPlayer: PlayerType) {
        unlistenWhenAppeared()
        let listener = targetPlayer.timeEvent.addHandler(self, handler: { (pc) -> Duration -> () in
            pc.onTimeUpdated
        })
        let stateListener = targetPlayer.stateEvent.addHandler(self, handler: { (pc) -> PlaybackState -> () in
            pc.onStateChanged
        })
        appearedListeners = [listener, stateListener]
    }
    
    func unlistenWhenAppeared() {
        for listener in appearedListeners {
            listener.dispose()
        }
        appearedListeners = []
    }
    
    private func reinstallListeners(targetPlayer: PlayerType) {
        unlistenWhenAppeared()
        unlistenWhenLoaded()
        listenWhenLoaded(targetPlayer)
        listenWhenAppeared(targetPlayer)
    }

}
