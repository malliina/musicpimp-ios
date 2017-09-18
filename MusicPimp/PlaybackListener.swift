//
//  PlaybackListener.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

protocol PlaybackEventDelegate {
    func onTrackChanged(_ track: Track?)
    func onTimeUpdated(_ position: Duration)
    func onStateChanged(_ state: PlaybackState)
}

class TrackListener: PlaybackEventDelegate {
    let onTrack: (Track?) -> Void
    
    init(onTrack: @escaping (Track?) -> Void) {
        self.onTrack = onTrack
    }
    
    func onTrackChanged(_ track: Track?) {
        self.onTrack(track)
    }
    
    func onTimeUpdated(_ position: Duration) {}
    
    func onStateChanged(_ state: PlaybackState) {}
}

class PlaybackListener: Disposable {
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var player: PlayerType { return playerManager.active }
    var playerSubscription: Disposable? = nil
    var playerSubscriptions: [Disposable] = []
    var delegate: PlaybackEventDelegate? = nil

    convenience init() {
        self.init(autoSubscribe: false)
    }
    
    init(autoSubscribe: Bool) {
        subscribePlayer()
        if autoSubscribe {
            subscribe(to: player)
        }
    }
    
    func onNewPlayer(_ newPlayer: PlayerType) {
        subscribe(to: newPlayer)
    }
    
    func updateTrack(_ track: Track?) {
        delegate?.onTrackChanged(track)
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
        delegate?.onTimeUpdated(position)
    }
    
    func onStateChanged(_ state: PlaybackState) {
        delegate?.onStateChanged(state)
    }
    
    func subscribePlayer() {
        playerSubscription?.dispose()
        playerSubscription = playerManager.playerChanged.addHandler(self) { (pc) -> (PlayerType) -> () in
            pc.onNewPlayer
        }
    }
    
    func resubscribe() {
        unsubscribe()
        subscribePlayer()
        subscribe(to: player)
    }
    
    func unsubscribe() {
        playerSubscription?.dispose()
        unsubscribeCurrent()
    }
    
    func resubscribeCurrent() {
        subscribe(to: player)
    }
    
    func unsubscribeCurrent() {
        playerSubscriptions.forEach { $0.dispose() }
    }
    
    private func subscribe(to newPlayer: PlayerType) {
        unsubscribeCurrent()
        let trackListener = newPlayer.trackEvent.addHandler(self) { (pc) -> (Track?) -> () in
            pc.updateTrack
        }
        let timeListener = newPlayer.timeEvent.addHandler(self) { (pc) -> (Duration) -> () in
            pc.onTimeUpdated
        }
        let stateListener = newPlayer.stateEvent.addHandler(self) { (pc) -> (PlaybackState) -> () in
            pc.onStateChanged
        }
        playerSubscriptions = [trackListener, timeListener, stateListener]
    }
    
    func dispose() {
        unsubscribe()
    }
}
