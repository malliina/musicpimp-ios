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
    var stateEvent: Observable<PlaybackState> { return stateSubject }
    let timeSubject = PublishSubject<Duration>()
    var timeEvent: Observable<Duration> { return timeSubject }
    let trackSubject = PublishSubject<Track?>()
    var trackEvent: Observable<Track?> { return trackSubject }
    let volumeSubject = PublishSubject<VolumeValue>()
    var volumeEvent: Observable<VolumeValue> { return volumeSubject }
    let muteSubject = PublishSubject<Bool>()
    var muteEvent: Observable<Bool> { return muteSubject }

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
    
//    func resetAndPlay(_ track: Track) -> ErrorMessage? {
//        return socket.send([
//            JsonKeys.CMD: JsonKeys.PLAY as AnyObject,
//            JsonKeys.TRACK: track.id as AnyObject
//        ])
//    }
    
    func resetAndPlay(tracks: [Track]) -> ErrorMessage? {
        return socket.send([
            JsonKeys.CMD: "play_items" as AnyObject,
            "tracks": tracks.map { $0.id } as AnyObject,
            "folders": [] as AnyObject
        ])
    }
    
    func play() -> ErrorMessage? {
        return sendSimple(JsonKeys.RESUME)
    }
    
    func pause() -> ErrorMessage? {
        return sendSimple(JsonKeys.STOP)
    }
    
    func seek(_ position: Duration) -> ErrorMessage? {
        return sendValued(JsonKeys.SEEK, value: Int(position.seconds) as AnyObject)
    }
    
    func next() -> ErrorMessage? {
        return sendSimple(JsonKeys.NEXT)
    }
    
    func prev() -> ErrorMessage? {
        return sendSimple(JsonKeys.PREV)
    }
    
    func skip(_ index: Int)  -> ErrorMessage? {
        return sendValued(JsonKeys.SKIP, value: index as AnyObject)
    }
    
    func volume(_ newVolume: VolumeValue) -> ErrorMessage? {
        return sendValued(JsonKeys.VOLUME, value: newVolume.volume as AnyObject)
    }
    
    func sendValued(_ cmd: String, value: AnyObject) -> ErrorMessage? {
        let payload = PimpEndpoint.valuedCommand(cmd, value: value)
        return socket.send(payload)
    }
    
    func sendSimple(_ cmd: String) -> ErrorMessage? {
        let payload = PimpEndpoint.simpleCommand(cmd)
        return socket.send(payload as [String : AnyObject])
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
