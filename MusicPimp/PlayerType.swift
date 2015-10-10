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
    var volumeEvent: Event<Int> { get }
    var trackEvent: Event<Track?> { get }
    var playlist: PlaylistType { get }
    
    func open()
    func close()
    
    func current() -> PlayerState
    func resetAndPlay(track: Track)
    func play()
    func pause()
    func seek(position: Duration)
    func next()
    func prev()
    func skip(index: Int)
}