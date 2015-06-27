//
//  PimpPlayer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class PimpPlayer: PimpEndpoint, PlayerType, PlayerEventDelegate {
    var isLocal: Bool { get { return false } }
    let stateEvent = Event<PlaybackState>()
    let timeEvent = Event<Duration>()
    let trackEvent = Event<Track?>()
    let volumeEvent = Event<Int>()
    let muteEvent = Event<Bool>()

    let playlist: PlaylistType
    let socket: PimpSocket
    
    private var currentState = PlayerState.empty
    
    init(e: Endpoint) {
        let client = PimpHttpClient(baseURL: e.httpBaseUrl, authValue: e.authHeader)
        self.socket = PimpSocket(baseURL: e.wsBaseUrl + Endpoints.WS_PLAYBACK, authValue: e.authHeader)
        self.playlist = PimpPlaylist(socket: self.socket)
        super.init(endpoint: e, client: client)
    }
    func open() {
        self.socket.delegate = self
        self.socket.open()
    }
    func close() {
        //self.socket.delegate = nil
        self.socket.close()
    }
    func current() -> PlayerState {
        return currentState
    }
    func resetAndPlay(track: Track) {
        socket.send([
            JsonKeys.CMD: JsonKeys.PLAY,
            JsonKeys.TRACK: track.id
        ])
    }
    func play() {
        sendSimple(JsonKeys.RESUME)
    }
    func pause() {
        sendSimple(JsonKeys.STOP)
    }
    func seek(position: Duration) {
        sendValued(JsonKeys.SEEK, value: Int(position.seconds))
    }
    func next() {
        sendSimple(JsonKeys.NEXT)
    }
    func prev() {
        sendSimple(JsonKeys.PREV)
    }
    func skip(index: Int) {
        sendValued(JsonKeys.SKIP, value: index)
    }
    func sendValued(cmd: String, value: AnyObject) {
        let payload = PimpEndpoint.valuedCommand(cmd, value: value)
        socket.send(payload)
    }
    func sendSimple(cmd: String) {
        let payload = PimpEndpoint.simpleCommand(cmd)
        socket.send(payload)
    }
    func onTimeUpdated(pos: Duration) {
        currentState.position = pos
        timeEvent.raise(pos)
    }
    func onTrackChanged(track: Track?) {
        currentState.track = track
        trackEvent.raise(track)
    }
    func onMuteToggled(mute: Bool) {
        currentState.mute = mute
        muteEvent.raise(mute)
    }
    func onVolumeChanged(volume: Int) {
        currentState.volume = volume
        volumeEvent.raise(volume)
    }
    func onStateChanged(state: PlaybackState) {
        currentState.state = state
        stateEvent.raise(state)
    }
    func onIndexChanged(index: Int?) {
        currentState.playlistIndex = index
        playlist.indexEvent.raise(index)
    }
    func onPlaylistModified(tracks: [Track]) {
        currentState.playlist = tracks
        playlist.playlistEvent.raise(Playlist(tracks: tracks, index: currentState.playlistIndex))
    }
    func onState(state: PlayerState) {
        currentState = state
        onPlaylistModified(state.playlist)
        onIndexChanged(state.playlistIndex)
        onTrackChanged(state.track)
        onMuteToggled(state.mute)
        onVolumeChanged(state.volume)
        onTimeUpdated(state.position)
        onStateChanged(state.state)
    }
}
