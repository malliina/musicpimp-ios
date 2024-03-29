import Foundation

class PimpSocket: PlayerSocket {
  private let log = LoggerFactory.shared.pimp(PimpSocket.self)

  let limiter = Limiter.sharedInstance

  var delegate: PlayerEventDelegate = LoggingDelegate()

  init(baseURL: URL, authValue: String) {
    let headers = [
      HttpClient.AUTHORIZATION: authValue,
      HttpClient.ACCEPT: PimpHttpClient.PIMP_VERSION_18,
    ]
    super.init(baseURL: baseURL, headers: headers)
  }

  func send<T: Encodable>(_ json: T) async -> ErrorMessage? {
    if let socket = socket {
      let encoder = JSONEncoder()
      do {
        let data = try encoder.encode(json)
        guard let asString = String(data: data, encoding: .utf8) else {
          return ErrorMessage("JSON-to-String conversion failed.")
        }
        let ret = await socket.send(asString)
        log.info("Sent \(asString) to \(baseURL)) return value \(ret)")
        return nil
      } catch {
        return failWith("Unable to send payload, encountered non-JSON payload: '\(error)'.")
      }
    } else {
      return failWith("Unable to send payload, socket not available.")
    }
  }

  func failWith(_ message: String) -> ErrorMessage {
    log.error(message)
    return ErrorMessage(message)
  }

  override func on(message: String) async {
    guard let data = message.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
      log.error("Cannot read message data from: '\(message)'.")
      return
    }
    let decoder = JSONDecoder()
    do {
      let event = try decoder.decode(KeyedEvent.self, from: data)
      switch event.event {
      case JsonKeys.TIME_UPDATED:
        delegate.onTimeUpdated(try decoder.decode(TimeUpdated.self, from: data).position)
        break
      case JsonKeys.TRACK_CHANGED:
        delegate.onTrackChanged(try decoder.decode(TrackChanged.self, from: data).track)
        break
      case JsonKeys.MUTE_TOGGLED:
        delegate.onMuteToggled(try decoder.decode(MuteToggled.self, from: data).mute)
        break
      case JsonKeys.VOLUME_CHANGED:
        delegate.onVolumeChanged(
          VolumeValue(volume: try decoder.decode(VolumeChanged.self, from: data).volume))
        break
      case JsonKeys.PLAYSTATE_CHANGED:
        delegate.onStateChanged(try decoder.decode(PlayStateChanged.self, from: data).playbackState)
        break
      case JsonKeys.INDEX_CHANGED:
        let idx = try decoder.decode(IndexChanged.self, from: data).index
        delegate.onIndexChanged(idx >= 0 ? idx : nil)
        break
      case JsonKeys.PLAYLIST_MODIFIED:
        delegate.onPlaylistModified(try decoder.decode(PlaylistModified.self, from: data).playlist)
        break
      case JsonKeys.STATUS:
        delegate.onState(try decoder.decode(PlayerStateJson.self, from: data))
        break
      case JsonKeys.WELCOME:
        if let err = await send(SimpleCommand(cmd: JsonKeys.STATUS)) {
          log.error("Unable to send welcome message over socket: '\(err.message)'.")
        }
        break
      case JsonKeys.PING:
        break
      default:
        log.error("Unknown event: \(event)")
      }
    } catch let err {
      log.error("Failed to parse JSON. \(err). Message was: '\(message)'.")
    }
  }
}
