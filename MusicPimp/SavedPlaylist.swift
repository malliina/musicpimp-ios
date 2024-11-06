import Foundation

struct SavedPlaylists: Codable {
  let playlists: [SavedPlaylist]
}

struct SavedPlaylistResponse: Codable {
  let playlist: SavedPlaylist
}

struct SavedPlaylist: Codable {
  let id: PlaylistID?
  let name: String
  let trackCount: Int
  let duration: Duration
  let tracks: [Track]

  static func from(id: PlaylistID?, name: String, tracks: [Track]) -> SavedPlaylist {
    SavedPlaylist(id: id, name: name, trackCount: tracks.count, duration: Duration.Zero, tracks: tracks)
  }
  
  func strip() -> SavedPlaylistStripped {
    SavedPlaylistStripped(
      id: id, name: name, trackCount: trackCount, duration: duration, tracks: tracks.map { $0.id })
  }
}

struct SavePlaylistPayload: Codable {
  let playlist: SavedPlaylistStripped
}

struct SavedPlaylistStripped: Codable {
  let id: PlaylistID?
  let name: String
  let trackCount: Int
  let duration: Duration
  let tracks: [TrackID]
}
