import Foundation
import UIKit

class PimpTableController: FeedbackTable {
  private let log = LoggerFactory.shared.vc(PimpTableController.self)
  let maxNewDownloads = 300

  var libraryManager: LibraryManager { LibraryManager.sharedInstance }
  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var library: LibraryType { libraryManager.libraryUpdated }
  var player: PlayerType { playerManager.playerChanged }

  func onLoadError(_ error: Error) {
    clearItems()
    reloadTable(feedback: error.message)
    onError(error)
  }

  func clearItems() {

  }

  func playTracksChecked(_ tracks: [Track]) async -> [ErrorMessage] {
    await limitChecked {
      await self.playTracks(tracks)
    } ?? []
  }

  fileprivate func playTracks(_ tracks: [Track]) async -> [ErrorMessage] {
    let playResult = await player.resetAndPlay(tracks: tracks)
    let downloadResult = downloadIfNeeded(tracks.take(3))
    let result = playResult.map { [$0] } ?? []
    return downloadResult + result
  }

  func addTracksChecked(_ tracks: [Track]) async -> [ErrorMessage] {
    await limitChecked {
      await self.addTracks(tracks)
    } ?? []
  }

  fileprivate func addTracks(_ tracks: [Track]) async -> [ErrorMessage] {
    if !tracks.isEmpty {
      let errors = await player.playlist.add(tracks)
      if errors.isEmpty {
        return downloadIfNeeded(tracks.take(3))
      } else {
        return errors
      }
    } else {
      return []
    }
  }

  func playAndDownloadCheckedSingle(_ track: Track) async -> ErrorMessage? {
    let error = await limitChecked {
      return await self.playAndDownload(track)
    }
    return error ?? nil
  }

  fileprivate func playAndDownload(_ track: Track) async -> ErrorMessage? {
    let error = await player.resetAndPlay(tracks: [track])
    if error == nil {
      return downloadIfNeeded([track]).headOption()
    } else {
      return error
    }
  }

  func downloadIfNeeded(_ tracks: [Track]) -> [ErrorMessage] {
    if !library.isLocal && player.isLocal && settings.cacheEnabled {
      let newTracks = tracks.filter { !LocalLibrary.sharedInstance.contains($0) }
      let tracksToDownload = newTracks.take(maxNewDownloads)
      log.info("Downloading \(tracksToDownload.count) tracks")
      return tracksToDownload.flatMapOpt { (track) -> ErrorMessage? in
        startDownload(track)
      }
    } else {
      return []
    }
  }

  func startDownload(_ track: Track) -> ErrorMessage? {
    DownloadUpdater.instance.downloadIfNecessary(track: track, authValue: library.authValue)
  }
}
