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
    
    func playTracks(_ tracks: [Track]) -> [ErrorMessage] {
        return limitChecked {
            self.playTracks2(tracks)
        } ??  []
    }
    
    fileprivate func playTracks2(_ tracks: [Track]) -> [ErrorMessage] {
        if let first = tracks.first {
            let firstError = playAndDownload2(first)
            if let firstError = firstError {
                return [firstError]
            } else {
                return addTracks2(tracks.tail())
            }
        } else {
            return []
        }
    }
    
    func addTracks(_ tracks: [Track]) -> [ErrorMessage] {
        return limitChecked {
            self.addTracks2(tracks)
        } ?? []
    }
    
    fileprivate func addTracks2(_ tracks: [Track]) -> [ErrorMessage] {
        if !tracks.isEmpty {
            info("Adding \(tracks.count) tracks")
            let errors = player.playlist.add(tracks)
            if errors.isEmpty {
                return downloadIfNeeded(tracks)
            } else {
                return errors
            }
        } else {
            return []
        }
    }
    
    func playAndDownload(_ track: Track) -> ErrorMessage? {
        let error = limitChecked {
            return self.playAndDownload2(track)
        }
        return error ?? nil
    }
    
    fileprivate func playAndDownload2(_ track: Track) -> ErrorMessage? {
        let error = player.resetAndPlay(track)
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
            Log.info("Downloading \(tracksToDownload.count) tracks")
            return tracksToDownload.flatMapOpt({ (track) -> ErrorMessage? in
                startDownload(track)
            })
        } else {
            return []
        }
    }
    
    func startDownload(_ track: Track) -> ErrorMessage? {
        return DownloadUpdater.instance.download(track: track)
        //return nil
    }
}
