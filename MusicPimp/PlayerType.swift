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
    
    func resetAndPlay(_ track: Track) -> Bool
    
    func play()
    
    func pause()
    
    func seek(_ position: Duration)
    
    func next()
    
    func prev()
    
    func skip(_ index: Int)
    
    func volume(_ newVolume: VolumeValue)
}
