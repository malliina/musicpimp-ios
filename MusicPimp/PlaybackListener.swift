//
//  PlaybackListener.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class BaseListener: Disposable {
    var bag = DisposeBag()
    
    func unsubscribe() {
        bag = DisposeBag()
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
        LibraryManager.sharedInstance.libraryChanged.subscribe(onNext: { (library) in
            self.onLibraryChanged(library)
        }).disposed(by: bag)
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
        LibraryManager.sharedInstance.changed.subscribe(onNext: { (library) in
            self.libraryChanged(library)
        }).disposed(by: bag)
        PlayerManager.sharedInstance.changed.subscribe(onNext: { (player) in
            self.playerChanged(player)
        }).disposed(by: bag)
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
        subscribe(playerManager.playerChanged, self.onNewPlayer)
        subscribe(player.playlist.playlistEvent) { playlist in self.onNewPlaylist(playlist) }
        subscribe(player.playlist.indexEvent) { self.onIndexChanged($0) }
        subscribe(newPlayer.trackEvent) { self.updateTrack($0) }
        subscribe(newPlayer.timeEvent) { self.onTimeUpdated($0) }
        subscribe(newPlayer.stateEvent) { self.onStateChanged($0) }
    }
    
    func subscribe<T>(_ o: Observable<T>, _ onNext: @escaping (T) -> Void) {
        o.subscribe(onNext: { (t) in
            onNext(t)
        }).disposed(by: bag)
    }
    
    private func onNewPlayer(_ newPlayer: PlayerType) {
        moveSubscriptions(to: newPlayer)
        players?.onPlayerChanged(to: newPlayer)
    }
    
    private func moveSubscriptions(to newPlayer: PlayerType) {
        subscribe(to: newPlayer)
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
