//
//  PlaybackListener.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class BaseListener: Disposable {
    var subscriptions: [Disposable] = []
    
    func unsubscribe() {
        subscriptions.forEach { $0.dispose() }
        subscriptions = []
    }
    
    func dispose() {
        unsubscribe()
    }
}

protocol LibraryDelegate {
    func onLibraryChanged(to newLibrary: LibraryType)
}

class LibraryListener: BaseListener {
    var delegate: LibraryDelegate? = nil
    
    func subscribe() {
        subscriptions = [
            LibraryManager.sharedInstance.libraryChanged.addHandler(self) { (ivc) -> (LibraryType) -> () in
                ivc.onLibraryChanged
            }
        ]
    }
    
    func onLibraryChanged(_ newLibrary: LibraryType) {
        delegate?.onLibraryChanged(to: newLibrary)
    }
}

protocol LibraryEndpointDelegate {
    func onLibraryChanged(to newLibrary: Endpoint)
}

protocol PlayerEndpointDelegate {
    func onPlayerChanged(to newPlayer: Endpoint)
}

class EndpointsListener: BaseListener {
    var libraries: LibraryEndpointDelegate? = nil
    var players: PlayerEndpointDelegate? = nil
    
    func subscribe() {
        let libraryListener = LibraryManager.sharedInstance.changed.addHandler(self) { (ssc) -> (Endpoint) -> () in
            ssc.libraryChanged
        }
        let playerListener = PlayerManager.sharedInstance.changed.addHandler(self) { (ssc) -> (Endpoint) -> () in
            ssc.playerChanged
        }

        subscriptions = [libraryListener, playerListener]
    }
    
    private func libraryChanged(_ newLibrary: Endpoint) {
        libraries?.onLibraryChanged(to: newLibrary)
    }
    
    private func playerChanged(_ newPlayer: Endpoint) {
        players?.onPlayerChanged(to: newPlayer)
    }
}

protocol PlayersDelegate {
    func onPlayerChanged(to newPlayer: PlayerType)
}
protocol TrackEventDelegate {
    func onTrackChanged(_ track: Track?)
}
protocol PlaybackEventDelegate: TrackEventDelegate {
    func onTimeUpdated(_ position: Duration)
    func onStateChanged(_ state: PlaybackState)
}
protocol PlaylistEventDelegate {
    func onIndexChanged(to index: Int?)
    func onNewPlaylist(_ playlist: Playlist)
}

class PlaybackListener: BaseListener {
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var player: PlayerType { return playerManager.active }
    var players: PlayersDelegate? = nil
    var tracks: TrackEventDelegate? = nil
    var playbacks: PlaybackEventDelegate? = nil
    var playlists: PlaylistEventDelegate? = nil
    
    func subscribe() {
        subscribe(to: player)
    }
    
    private func subscribe(to newPlayer: PlayerType) {
        unsubscribe()
        let playerListener = playerManager.playerChanged.addHandler(self) { (pc) -> (PlayerType) -> () in
            pc.onNewPlayer
        }
        let playlistListener = player.playlist.playlistEvent.addHandler(self) { (pc) -> (Playlist) -> () in
            pc.onNewPlaylist
        }
        let indexListener = player.playlist.indexEvent.addHandler(self) { (pc) -> (Int?) -> () in
            pc.onIndexChanged
        }
        let trackListener = newPlayer.trackEvent.addHandler(self) { (pc) -> (Track?) -> () in
            pc.updateTrack
        }
        let timeListener = newPlayer.timeEvent.addHandler(self) { (pc) -> (Duration) -> () in
            pc.onTimeUpdated
        }
        let stateListener = newPlayer.stateEvent.addHandler(self) { (pc) -> (PlaybackState) -> () in
            pc.onStateChanged
        }
        subscriptions = [playerListener, playlistListener, indexListener, trackListener, timeListener, stateListener]
    }
    
    private func onNewPlayer(_ newPlayer: PlayerType) {
        moveSubscriptions(to: newPlayer)
        players?.onPlayerChanged(to: newPlayer)
    }
    
    private func moveSubscriptions(to newPlayer: PlayerType) {
        if !subscriptions.isEmpty {
            subscribe(to: newPlayer)
        }
    }
    
    private func onNewPlaylist(_ playlist: Playlist) {
        playlists?.onNewPlaylist(playlist)
    }
    
    private func onIndexChanged(_ to: Int?) {
        playlists?.onIndexChanged(to: to)
    }
    
    private func updateTrack(_ track: Track?) {
        tracks?.onTrackChanged(track)
        playbacks?.onTrackChanged(track)
    }
    
    private func onTimeUpdated(_ position: Duration) {
        playbacks?.onTimeUpdated(position)
    }
    
    private func onStateChanged(_ state: PlaybackState) {
        playbacks?.onStateChanged(state)
    }
}
