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
    
    func onLoadError(error: PimpError) {
        clearItems()
        let errorMessage = PimpError.stringify(error)
        renderTable(errorMessage)
        onError(error)
    }
    
    func clearItems() {
        
    }
    
    func playTracks(tracks: [Track]) {
        limitChecked {
            self.playTracks2(tracks)
        }
    }
    
    private func playTracks2(tracks: [Track]) {
        if let first = tracks.first {
            playAndDownload2(first)
            addTracks2(tracks.tail())
        }
    }
    
    func addTracks(tracks: [Track]) {
        limitChecked {
            self.addTracks2(tracks)
        }
    }
    
    private func addTracks2(tracks: [Track]) {
        if !tracks.isEmpty {
            info("Adding \(tracks.count) tracks")
            player.playlist.add(tracks)
            downloadIfNeeded(tracks)
        }
    }
    
    func playAndDownload(track: Track) {
        limitChecked {
            self.playAndDownload2(track)
        }
    }
    
    private func playAndDownload2(track: Track) {
        player.resetAndPlay(track)
        downloadIfNeeded([track])
    }
    
    func downloadIfNeeded(tracks: [Track]) {
        if !library.isLocal && player.isLocal && settings.cacheEnabled {
            let newTracks = tracks.filter({ !LocalLibrary.sharedInstance.contains($0) })
            let tracksToDownload = newTracks.take(maxNewDownloads)
            for track in tracksToDownload {
                startDownload(track)
            }
        }
    }
    
    func startDownload(track: Track) {
        BackgroundDownloader.musicDownloader.download(track.url, relativePath: track.path)
    }
}
