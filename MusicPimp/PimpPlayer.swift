//
//  PimpPlayer.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

class PimpPlayer: PimpEndpoint, PlayerType, PlayerEventDelegate {
    var isLocal: Bool { get { return false } }
    let stateSubject = PublishSubject<PlaybackState>()
    var stateEvent: Observable<PlaybackState> { stateSubject }
    let timeSubject = PublishSubject<Duration>()
    var timeEvent: Observable<Duration> { timeSubject }
    let trackSubject = PublishSubject<Track?>()
    var trackEvent: Observable<Track?> { trackSubject }
    let volumeSubject = PublishSubject<VolumeValue>()
    var volumeEvent: Observable<VolumeValue> { volumeSubject }
    let muteSubject = PublishSubject<Bool>()
    var muteEvent: Observable<Bool> { muteSubject }

    let playlist: PlaylistType
    let socket: PimpSocket
    
    fileprivate var currentState = PlayerState.empty
    
    init(e: Endpoint) {
        let client = PimpHttpClient(baseURL: e.httpBaseUrl, authValue: e.authHeader)
        self.socket = PimpSocket(baseURL: URL(string: Endpoints.WS_PLAYBACK, relativeTo: e.wsBaseUrl)!, authValue: e.authHeader)
        self.playlist = PimpPlaylist(socket: self.socket)
        super.init(endpoint: e, client: client)
    }
    
    func open() -> Observable<Void> {
        self.socket.delegate = self
        return self.socket.open()
    }
    
    func close() {
        //self.socket.delegate = nil
        self.socket.close()
    }
    
    func current() -> PlayerState {
        return currentState
    }
    
    func resetAndPlay(tracks: [Track]) -> ErrorMessage? {
        return socket.send(PlayItems(tracks: tracks))
    }
    
    func play() -> ErrorMessage? {
        return sendSimple(JsonKeys.RESUME)
    }
    
    func pause() -> ErrorMessage? {
        return sendSimple(JsonKeys.STOP)
    }
    
    func seek(_ position: Duration) -> ErrorMessage? {
        return sendValued(IntPayload(seek: position))
    }
    
    func next() -> ErrorMessage? {
        return sendSimple(JsonKeys.NEXT)
    }
    
    func prev() -> ErrorMessage? {
        return sendSimple(JsonKeys.PREV)
    }
    
    func skip(_ index: Int)  -> ErrorMessage? {
        return sendValued(IntPayload(skip: index))
    }
    
    func volume(_ newVolume: VolumeValue) -> ErrorMessage? {
        return sendValued(IntPayload(volumeChanged: newVolume.volume))
    }
    
    func sendValued<T: Encodable>(_ t: T) -> ErrorMessage? {
        return socket.send(t)
    }
    
    func sendSimple(_ cmd: String) -> ErrorMessage? {
        return socket.send(SimpleCommand(cmd: cmd))
    }
    
    func onTimeUpdated(_ pos: Duration) {
        currentState.position = pos
        timeSubject.onNext(pos)
    }
    
    func onTrackChanged(_ track: Track?) {
        currentState.track = track
        trackSubject.onNext(track)
        if let _ = track {
            Limiter.sharedInstance.increment()
        }
    }
    
    func onMuteToggled(_ mute: Bool) {
        currentState.mute = mute
        muteSubject.onNext(mute)
    }
    
    func onVolumeChanged(_ volume: VolumeValue) {
        currentState.volume = volume
        volumeSubject.onNext(volume)
    }
    
    func onStateChanged(_ state: PlaybackState) {
        currentState.state = state
        stateSubject.onNext(state)
    }
    
    func onIndexChanged(_ index: Int?) {
        currentState.playlistIndex = index
        playlist.indexSubject.onNext(index)
    }
    
    func onPlaylistModified(_ tracks: [Track]) {
        currentState.playlist = tracks
        playlist.playlistSubject.onNext(Playlist(tracks: tracks, index: currentState.playlistIndex))
    }
    
    func onState(_ state: PlayerStateJson) {
        currentState = state.mutable()
        onPlaylistModified(state.playlist)
        onIndexChanged(state.index)
        onTrackChanged(state.track)
        onMuteToggled(state.mute)
        onVolumeChanged(state.volume)
        onTimeUpdated(state.position)
        onStateChanged(state.playbackState)
    }
}
