import Foundation
import MediaPlayer

class ExternalCommandDelegate: NSObject {
  static let sharedInstance = ExternalCommandDelegate()

  let log = LoggerFactory.shared.pimp(ExternalCommandDelegate.self)
  var player: PlayerType { PlayerManager.sharedInstance.playerChanged }

  func initialize(_ commandCenter: MPRemoteCommandCenter) {
    commandCenter.playCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onPlay))
    commandCenter.pauseCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onPause))
    commandCenter.togglePlayPauseCommand.addTarget(
      self, action: #selector(ExternalCommandDelegate.onTogglePlayPause))
    commandCenter.stopCommand.addTarget(self, action: #selector(ExternalCommandDelegate.onStop))
    commandCenter.nextTrackCommand.addTarget(self, action: #selector(ExternalCommandDelegate.next))
    commandCenter.previousTrackCommand.addTarget(
      self, action: #selector(ExternalCommandDelegate.prev))
    // these two will visually replace the "prev" and "next" buttons, which I don't want, so I exclude them
    //        commandCenter.skipForwardCommand.addTarget(self, action: "skipForward:")
    //        commandCenter.skipBackwardCommand.addTarget(self, action: "skipBackward:")
    commandCenter.seekForwardCommand.addTarget(
      self, action: #selector(ExternalCommandDelegate.seekForward(_:)))
    commandCenter.seekBackwardCommand.addTarget(
      self, action: #selector(ExternalCommandDelegate.seekBackward(_:)))
    Task {
      for await track in LocalPlayer.sharedInstance.trackEvent.values {
        onLocalTrackChanged(track)
      }
    }
  }

  func onLocalTrackChanged(_ track: Track?) {
    let center = MPNowPlayingInfoCenter.default()
    if let track = track {

      Task {
        var info: [String: AnyObject] = [
          MPMediaItemPropertyTitle: track.title as AnyObject,
          MPMediaItemPropertyArtist: track.artist as AnyObject,
          MPMediaItemPropertyAlbumTitle: track.album as AnyObject,
          MPMediaItemPropertyMediaType: MPMediaType.music.rawValue as AnyObject,
          MPMediaItemPropertyPlaybackDuration: TimeInterval(track.duration.seconds) as AnyObject,
        ]
        let result = await CoverService.sharedInstance.cover(track.artist, album: track.album)
        if let image = result.imageOrDefault {
          info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
            boundsSize: image.size, requestHandler: { size in image.withSize(scaledToSize: size) })
        }
        center.nowPlayingInfo = info
      }
    } else {
      center.nowPlayingInfo = nil
    }
  }

  @objc func onPlay() -> MPRemoteCommandHandlerStatus {
    Task {
      _ = await player.play()
    }
    info("onPlay")
    return .success
  }

  @objc func onPause() -> MPRemoteCommandHandlerStatus {
    Task {
      _ = await player.pause()
    }
    info("onPause")
    return .success
  }

  @objc func onTogglePlayPause() -> MPRemoteCommandHandlerStatus {
    Task {
      if player.current().isPlaying {
        _ = await player.pause()
      } else {
        _ = await player.play()
      }
    }
    info("onTogglePlayPause")
    return .success
  }

  @objc func onStop() -> MPRemoteCommandHandlerStatus {
    Task {
      _ = await player.pause()
    }
    info("onStop")
    return .success
  }

  @objc func next() -> MPRemoteCommandHandlerStatus {
    Task {
      _ = await player.next()
    }
    info("next")
    return .success
  }

  @objc func prev() -> MPRemoteCommandHandlerStatus {
    Task {
      _ = await player.prev()
    }
    info("prev")
    return .success
  }

  func skipForward(_ skipEvent: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
    let interval = skipEvent.interval
    info("skipForward \(interval)")
    return .success
  }

  func skipBackward(_ skipEvent: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
    info("skipBackward")
    return .success
  }

  @objc func seekForward(_ seekEvent: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
    let t = seekEvent.type
    info("seekForward \(t)")
    return .success
  }

  @objc func seekBackward(_ seekEvent: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
    info("seekBackward")
    return .success
  }

  func info(_ s: String) {
    log.info(s)
  }
}
