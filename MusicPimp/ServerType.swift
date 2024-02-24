import Foundation

enum ServerType: String, Codable {
  case cloud = "Cloud"
  case musicPimp = "MusicPimp"
  case subsonic = "Subsonic"
  case local = "Local"

  var isCloud: Bool { name == ServerType.cloud.name }

  var name: String {
    return switch self {
    case .cloud: "Cloud"
    case .musicPimp: "MusicPimp"
    case .subsonic: "Subsonic"
    case .local: "Local"
    }
  }

  var index: Int {
    return switch self {
    case .cloud: 0
    case .musicPimp: 1
    case .subsonic: 2
    case .local: 3
    }
  }
}

class ServerTypes {
  static let all: [ServerType] = [.cloud, .musicPimp, .subsonic]

  static func fromIndex(_ i: Int) -> ServerType? {
    all.find { $0.index == i }
  }
  static func fromName(_ name: String) -> ServerType? {
    all.find { $0.name == name }
  }
}
