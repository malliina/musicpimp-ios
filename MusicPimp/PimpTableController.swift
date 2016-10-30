//
//  PimpTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PimpTableController: FeedbackTable {
    
    let maxNewDownloads = 2000
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var library: LibraryType { return libraryManager.active }
    var player: PlayerType { return playerManager.active }
    
    func onLoadError(_ error: PimpError) {
        clearItems()
        let errorMessage = PimpError.stringify(error)
        renderTable(errorMessage)
        onError(error)
    }
    
    func clearItems() {
        
    }
    
    func playTracks(_ tracks: [Track]) {
        limitChecked {
            self.playTracks2(tracks)
        }
    }
    
    fileprivate func playTracks2(_ tracks: [Track]) {
        if let first = tracks.first {
            playAndDownload2(first)
            addTracks2(tracks.tail())
        }
    }
    
    func addTracks(_ tracks: [Track]) {
        limitChecked {
            self.addTracks2(tracks)
        }
    }
    
    fileprivate func addTracks2(_ tracks: [Track]) {
        if !tracks.isEmpty {
            info("Adding \(tracks.count) tracks")
            player.playlist.add(tracks)
            downloadIfNeeded(tracks)
        }
    }
    
    func playAndDownload(_ track: Track) {
        limitChecked {
            self.playAndDownload2(track)
        }
    }
    
    fileprivate func playAndDownload2(_ track: Track) {
        player.resetAndPlay(track)
        downloadIfNeeded([track])
    }
    
    func downloadIfNeeded(_ tracks: [Track]) {
        if !library.isLocal && player.isLocal && settings.cacheEnabled {
            let newTracks = tracks.filter({ !LocalLibrary.sharedInstance.contains($0) })
            let tracksToDownload = newTracks.take(maxNewDownloads)
            for track in tracksToDownload {
                startDownload(track)
            }
        }
    }
    
    func startDownload(_ track: Track) {
        DownloadUpdater.instance.download(track: track)
//        BackgroundDownloader.musicDownloader.download(track.url, relativePath: track.path)
    }
}
