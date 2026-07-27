import Foundation

protocol TopEntry {
  var entry: Track { get }
  var id: String { get }
}

struct Populars: Codable {
  let populars: [PopularEntry]
}

struct PopularEntry: Codable, TopEntry {
  let track: Track
  var entry: Track { track }
  let playbackCount: Int
  var id: String { "\(track.idStr)-\(playbackCount)" }
}
