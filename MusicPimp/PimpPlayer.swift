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
    let volumeEvent = Event<VolumeValue>()
    let muteEvent = Event<Bool>()

    let playlist: PlaylistType
    let socket: PimpSocket
    
    fileprivate var currentState = PlayerState.empty
    
    init(e: Endpoint) {
        let client = PimpHttpClient(baseURL: e.httpBaseUrl, authValue: e.authHeader)
        self.socket = PimpSocket(baseURL: URL(string: Endpoints.WS_PLAYBACK, relativeTo: e.wsBaseUrl)!, authValue: e.authHeader)
        self.playlist = PimpPlaylist(socket: self.socket)
        super.init(endpoint: e, client: client)
    }
    
    func open(_ onOpen: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.socket.delegate = self
        self.socket.open(onOpen, onError: onError)
    }
    
    func close() {
        //self.socket.delegate = nil
        self.socket.close()
    }
    
    func current() -> PlayerState {
        return currentState
    }
    
    func resetAndPlay(_ track: Track) -> Bool {
//        Limiter.sharedInstance.increment()
        return socket.send([
            JsonKeys.CMD: JsonKeys.PLAY as AnyObject,
            JsonKeys.TRACK: track.id as AnyObject
        ])
    }
    
    func play() {
        sendSimple(JsonKeys.RESUME)
    }
    
    func pause() {
        sendSimple(JsonKeys.STOP)
    }
    
    func seek(_ position: Duration) {
        sendValued(JsonKeys.SEEK, value: Int(position.seconds) as AnyObject)
    }
    
    func next() {
        sendSimple(JsonKeys.NEXT)
    }
    
    func prev() {
        sendSimple(JsonKeys.PREV)
    }
    
    func skip(_ index: Int) {
        sendValued(JsonKeys.SKIP, value: index as AnyObject)
    }
    
    func volume(_ newVolume: VolumeValue) {
        sendValued(JsonKeys.VOLUME, value: newVolume.volume as AnyObject)
    }
    
    func sendValued(_ cmd: String, value: AnyObject) {
        let payload = PimpEndpoint.valuedCommand(cmd, value: value)
        socket.send(payload)
    }
    
    func sendSimple(_ cmd: String) {
        let payload = PimpEndpoint.simpleCommand(cmd)
        socket.send(payload as [String : AnyObject])
    }
    
    func onTimeUpdated(_ pos: Duration) {
        currentState.position = pos
        timeEvent.raise(pos)
    }
    
    func onTrackChanged(_ track: Track?) {
        currentState.track = track
        trackEvent.raise(track)
        if let _ = track {
            Limiter.sharedInstance.increment()
        }
    }
    
    func onMuteToggled(_ mute: Bool) {
        currentState.mute = mute
        muteEvent.raise(mute)
    }
    
    func onVolumeChanged(_ volume: VolumeValue) {
        currentState.volume = volume
        volumeEvent.raise(volume)
    }
    
    func onStateChanged(_ state: PlaybackState) {
        currentState.state = state
        stateEvent.raise(state)
    }
    
    func onIndexChanged(_ index: Int?) {
        currentState.playlistIndex = index
        playlist.indexEvent.raise(index)
    }
    
    func onPlaylistModified(_ tracks: [Track]) {
        currentState.playlist = tracks
        playlist.playlistEvent.raise(Playlist(tracks: tracks, index: currentState.playlistIndex))
    }
    
    func onState(_ state: PlayerState) {
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
