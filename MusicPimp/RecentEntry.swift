import Foundation

struct Recents: Codable {
  let recents: [RecentEntry]
}

struct RecentEntry: Codable, TopEntry {
  static let When = "when"

  let track: Track
  var entry: Track { track }
  // milliseconds
  let when: UInt64

  var timestamp: Date { Date(timeIntervalSince1970: Double(when) / 1000) }
}
