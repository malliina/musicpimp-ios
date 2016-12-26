//
//  PlayerType.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

protocol PlayerType {
    var isLocal: Bool { get }
    var stateEvent: Event<PlaybackState> { get }
    var timeEvent: Event<Duration> { get }
    var volumeEvent: Event<VolumeValue> { get }
    var trackEvent: Event<Track?> { get }
    var playlist: PlaylistType { get }
    
    func open(_ onOpen: @escaping () -> Void, onError: @escaping (Error) -> Void)
    
    func close()
    
    func current() -> PlayerState
    
    /// Resets the playlist to the given track only, and starts playback.
    ///
    /// - parameter track: track to play
    ///
    /// - returns: an error message, if any
    func resetAndPlay(_ track: Track) -> ErrorMessage?
    
    func play() -> ErrorMessage?
    
    func pause() -> ErrorMessage?
    
    func seek(_ position: Duration) -> ErrorMessage?
    
    func next() -> ErrorMessage?
    
    func prev() -> ErrorMessage?
    
    func skip(_ index: Int) -> ErrorMessage?
    
    func volume(_ newVolume: VolumeValue) -> ErrorMessage?
}
