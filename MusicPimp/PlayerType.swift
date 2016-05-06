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
    
    func open(onOpen: () -> Void, onError: NSError -> Void)
    
    func close()
    
    func current() -> PlayerState
    
    func resetAndPlay(track: Track) -> Bool
    
    func play()
    
    func pause()
    
    func seek(position: Duration)
    
    func next()
    
    func prev()
    
    func skip(index: Int)
    
    func volume(newVolume: VolumeValue)
}
