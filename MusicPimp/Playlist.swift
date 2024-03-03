import Foundation

struct Playlist {
  static let empty = Playlist(tracks: [], index: nil)

  let tracks: [Track]
  let index: Int?
}
