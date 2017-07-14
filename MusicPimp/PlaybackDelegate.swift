//
//  PlaybackFooter.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 22/04/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

protocol PlaybackDelegate {
    func onPlayPause()
    func onPrev()
    func onNext()
}
