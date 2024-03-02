import Foundation

open class BaseLibrary: LibraryType {
  var id: String { "" }
  var isLocal: Bool { false }
  var rootFolderKey: String { "" }
  var authValue: String { "" }
  var authQuery: String { "" }
  @Published var contentsUpdated: MusicFolder?
  var contentsUpdatedPublisher: Published<MusicFolder?>.Publisher { $contentsUpdated }
  
  let notImplementedError = PimpError.simpleError(ErrorMessage("Not implemented yet"))

  func pingAuth() async throws -> Version {
    throw notImplementedError
  }

  func folder(_ id: FolderID) async throws -> MusicFolder {
    throw notImplementedError
  }

  func rootFolder() async throws -> MusicFolder {
    throw notImplementedError
  }

  func tracks(_ id: FolderID) async throws -> [Track] {
    try await tracksInner(id, others: [], acc: [])
  }

  // the saved playlists
  func playlists() async throws -> [SavedPlaylist] {
    []
  }

  func playlist(_ id: PlaylistID) async throws -> SavedPlaylist {
    throw notImplementedError
  }

  func popular(_ from: Int, until: Int) async throws -> [PopularEntry] {
    throw notImplementedError
  }

  func recent(_ from: Int, until: Int) async throws -> [RecentEntry] {
    throw notImplementedError
  }

  func savePlaylist(_ sp: SavedPlaylist) async throws -> PlaylistID {
    throw notImplementedError
  }

  func deletePlaylist(_ id: PlaylistID) async throws -> HttpResponse {
    throw notImplementedError
  }

  func search(_ term: String) async throws -> [Track] {
    []
  }

  func alarms() async throws -> [Alarm] {
    []
  }

  func saveAlarm(_ alarm: Alarm) async throws -> HttpResponse {
    throw notImplementedError
  }

  func deleteAlarm(_ id: AlarmID) async throws -> HttpResponse {
    throw notImplementedError
  }

  func stopAlarm() async throws -> HttpResponse {
    throw notImplementedError
  }

  func registerNotifications(_ token: PushToken, tag: String) async throws -> HttpResponse {
    throw notImplementedError
  }

  func unregisterNotifications(_ tag: String) async throws -> HttpResponse {
    throw notImplementedError
  }

  func tracksInner(_ id: FolderID, others: [FolderID], acc: [Track]) async throws -> [Track] {
    let result = try await folder(id)
    let subIDs = result.folders.map { $0.id }
    let remaining = others + subIDs
    let newAcc = acc + result.tracks
    if let head = remaining.first {
      let tail = remaining.tail()
      return try await self.tracksInner(head, others: tail, acc: newAcc)
    } else {
      return newAcc
    }
  }
}
