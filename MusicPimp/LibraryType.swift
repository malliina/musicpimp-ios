import Foundation

protocol LibraryType {
  var id: String { get }
  var isLocal: Bool { get }
  var authValue: String { get }
  var authQuery: String { get }
  var contentsUpdatedPublisher: Published<MusicFolder?>.Publisher { get }
  var rootFolderKey: String { get }

  func pingAuth() async throws -> Version

  func rootFolder() async throws -> MusicFolder
  func folder(_ id: FolderID) async throws -> MusicFolder
  func tracks(_ id: FolderID) async throws -> [Track]
  func search(_ term: String) async throws -> [Track]

  func playlists() async throws -> [SavedPlaylist]
  func playlist(_ id: PlaylistID) async throws -> SavedPlaylist
  func popular(_ from: Int, until: Int) async throws -> [PopularEntry]
  func recent(_ from: Int, until: Int) async throws -> [RecentEntry]
  func savePlaylist(_ sp: SavedPlaylist) async throws -> PlaylistID
  func deletePlaylist(_ id: PlaylistID) async throws -> HttpResponse

  func alarms() async throws -> [Alarm]
  func saveAlarm(_ alarm: Alarm) async throws -> HttpResponse
  func deleteAlarm(_ id: AlarmID) async throws -> HttpResponse
  func stopAlarm() async throws -> HttpResponse
  func registerNotifications(_ token: PushToken, tag: String) async throws -> HttpResponse
  func unregisterNotifications(_ tag: String) async throws -> HttpResponse
}
