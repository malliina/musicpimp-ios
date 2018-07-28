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
    private let log = LoggerFactory.shared.vc(PimpTableController.self)
    let maxNewDownloads = 300
    
    var libraryManager: LibraryManager { return LibraryManager.sharedInstance }
    var playerManager: PlayerManager { return PlayerManager.sharedInstance }
    var library: LibraryType { return libraryManager.active }
    var player: PlayerType { return playerManager.active }
    
    func onLoadError(_ error: Error) {
        clearItems()
        renderTable(error.message)
        onError(error)
    }
    
    func clearItems() {
        
    }
    
    func playTracksChecked(_ tracks: [Track]) -> [ErrorMessage] {
        return limitChecked {
            self.playTracks(tracks)
        } ??  []
    }
    
    fileprivate func playTracks(_ tracks: [Track]) -> [ErrorMessage] {
        let playResult = player.resetAndPlay(tracks: tracks)
        let downloadResult = downloadIfNeeded(tracks.take(3))
        let result = playResult.map { [$0] } ?? []
        return downloadResult + result
    }
    
    func addTracksChecked(_ tracks: [Track]) -> [ErrorMessage] {
        return limitChecked {
            self.addTracks(tracks)
        } ?? []
    }
    
    fileprivate func addTracks(_ tracks: [Track]) -> [ErrorMessage] {
        if !tracks.isEmpty {
            let errors = player.playlist.add(tracks)
            if errors.isEmpty {
                return downloadIfNeeded(tracks.take(3))
            } else {
                return errors
            }
        } else {
            return []
        }
    }
    
    func playAndDownloadCheckedSingle(_ track: Track) -> ErrorMessage? {
        let error = limitChecked {
            return self.playAndDownload(track)
        }
        return error ?? nil
    }
    
    fileprivate func playAndDownload(_ track: Track) -> ErrorMessage? {
        let error = player.resetAndPlay(tracks: [track])
        if error == nil {
            return downloadIfNeeded([track]).headOption()
        } else {
            return error
        }
    }
    
    func downloadIfNeeded(_ tracks: [Track]) -> [ErrorMessage] {
        if !library.isLocal && player.isLocal && settings.cacheEnabled {
            let newTracks = tracks.filter({ !LocalLibrary.sharedInstance.contains($0) })
            let tracksToDownload = newTracks.take(maxNewDownloads)
            log.info("Downloading \(tracksToDownload.count) tracks")
            return tracksToDownload.flatMapOpt({ (track) -> ErrorMessage? in
                startDownload(track)
            })
        } else {
            return []
        }
    }
    
    func startDownload(_ track: Track) -> ErrorMessage? {
        return DownloadUpdater.instance.downloadIfNecessary(track: track)
    }
}
