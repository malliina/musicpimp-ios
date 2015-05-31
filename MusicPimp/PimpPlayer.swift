//
//  PimpPlayer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class PimpPlayer: PimpEndpoint, PlayerType, PlayerEventDelegate {
//    class Endpoints {
//        static let PLAYBACK = "/playback"
//    }
    let endpoint: Endpoint
    let stateEvent = Event<PlaybackState>()
    let timeEvent = Event<Float>()
    let trackEvent = Event<Track>()
    let volumeEvent = Event<Int>()
    let muteEvent = Event<Bool>()

    let playlist: PlaylistType
    
    private var currentState = PlayerState.empty
    
    var socket: PimpSocket? = nil
    
    init(e: Endpoint) {
        self.endpoint = e
        let client = PimpHttpClient(baseURL: e.httpBaseUrl, username: e.username, password: e.password)
        self.playlist = PimpPlaylist(client: client)
        super.init(client: client)
    }
    // idempotent
    func open() {
        if self.socket == nil {
            self.socket = PimpSocket(baseURL: endpoint.wsBaseUrl + Endpoints.WS_PLAYBACK, username: endpoint.username, password: endpoint.password, delegate: self)
            self.socket?.open()
        }
    }
    func close() {
        self.socket?.close()
        self.socket = nil
    }
    func current() -> PlayerState {
        return currentState
    }
    func resetAndPlay(track: Track) {
        postDict([
            JsonKeys.CMD: JsonKeys.PLAY,
            JsonKeys.TRACK: track.id
        ])
    }
    func play() {
        postPlayback(JsonKeys.RESUME)
    }
    func pause() {
        postPlayback(JsonKeys.STOP)
    }
    func seek(position: Float) {
        postValued(JsonKeys.SEEK, value: position)
    }
    func next() {
        postPlayback(JsonKeys.NEXT)
    }
    func prev() {
        postPlayback(JsonKeys.PREV)
    }
    func skip(index: Int) {
        postValued(JsonKeys.SKIP, value: index)
    }
    func onTimeUpdated(pos: Int) {
        timeEvent.raise(Float(pos))
    }
    func onTrackChanged(track: Track?) {
        if let track = track {
            trackEvent.raise(track)
        }
    }
    func onMuteToggled(mute: Bool) {
        muteEvent.raise(mute)
    }
    func onVolumeChanged(volume: Int) {
        volumeEvent.raise(volume)
    }
    func onStateChanged(state: PlaybackState) {
        stateEvent.raise(state)
    }
    func onIndexChanged(index: Int?) {
        playlist.indexEvent.raise(index)
    }
    func onPlaylistModified(tracks: [Track]) {
        playlist.playlistEvent.raise(Playlist(tracks: tracks, index: currentState.playlistIndex))
    }
}
