import Foundation

enum PlaybackState: String {
  case Playing = "Playing"
  case Paused = "Paused"
  case Stopped = "Stopped"
  case NoMedia = "NoMedia"
  case Unknown = "Unknown"

  static func from(state: PlayStateJson) -> PlaybackState {
    switch state {
    case .closed: return .Stopped
    case .open: return .Paused
    case .started: return .Playing
    default: return .Unknown
    }
  }
}

enum PlayStateJson: String, Codable {
  case closed = "Closed"
  case open = "Open"
  case started = "Started"
  case stopped = "Stopped"
  case noMedia = "NoMedia"

  var playbackState: PlaybackState { return PlaybackState.from(state: self) }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let raw = try container.decode(String.self)
    switch raw {
    case "Closed": self = .closed
    case "Open": self = .open
    case "Started": self = .started
    case "Stopped": self = .stopped
    case "NoMedia": self = .noMedia
    default: self = .noMedia
    }
  }
}
