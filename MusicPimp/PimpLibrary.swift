import Foundation

open class PimpLibrary: BaseLibrary {
  static let log = LoggerFactory.shared.pimp(PimpLibrary.self)
  let endpoint: Endpoint
  let client: PimpHttpClient
  override var authValue: String { endpoint.authHeader }
  override var authQuery: String { endpoint.authQueryString }

  let identifier: String
  override var id: String { identifier }

  init(endpoint: Endpoint, client: PimpHttpClient) {
    self.endpoint = endpoint
    self.client = client
    self.identifier = endpoint.id
  }

  override func pingAuth() async throws -> Version {
    try await client.pingAuth()
  }

  override func rootFolder() async throws -> MusicFolder {
    try await client.pimpGetParsed(Endpoints.FOLDERS, to: MusicFolder.self)
  }

  override func folder(_ id: FolderID) async throws -> MusicFolder {
    try await client.pimpGetParsed("\(Endpoints.FOLDERS)/\(id)", to: MusicFolder.self)
  }

  override func tracks(_ id: FolderID) async throws -> [Track] {
    try await tracksInner(id, others: [], acc: [])
  }

  override func playlists() async throws -> [SavedPlaylist] {
    let res = try await client.pimpGetParsed("\(Endpoints.PLAYLISTS)", to: SavedPlaylists.self)
    return res.playlists
  }

  override func playlist(_ id: PlaylistID) async throws -> SavedPlaylist {
    let res = try await client.pimpGetParsed(
      "\(Endpoints.PLAYLISTS)\(id.id)", to: SavedPlaylistResponse.self)
    return res.playlist
  }

  override func popular(_ from: Int, until: Int) async throws -> [PopularEntry] {
    let res = try await client.pimpGetParsed(
      "\(Endpoints.Popular)?from=\(from)&until=\(until)", to: Populars.self)
    return res.populars
  }

  override func recent(_ from: Int, until: Int) async throws -> [RecentEntry] {
    let res = try await client.pimpGetParsed(
      "\(Endpoints.Recent)?from=\(from)&until=\(until)", to: Recents.self)
    return res.recents
  }

  override func savePlaylist(_ sp: SavedPlaylist) async throws -> PlaylistID {
    let res = try await client.pimpPostParsed(
      Endpoints.PLAYLISTS, payload: SavePlaylistPayload(playlist: sp.strip()),
      to: PlaylistIdResponse.self
    )
    return res.id
  }

  override func deletePlaylist(_ id: PlaylistID) async throws -> HttpResponse {
    try await client.pimpPostEmpty("\(Endpoints.PLAYLIST_DELETE)/\(id.id)")
  }

  override func search(_ term: String) async throws -> [Track] {
    if let encodedTerm = term.addingPercentEncoding(
      withAllowedCharacters: CharacterSet.urlQueryAllowed)
    {
      return try await client.pimpGetParsed(
        "\(Endpoints.SEARCH)?term=\(encodedTerm)", to: [Track].self)
    } else {
      throw PimpError.simple("Invalid search term: \(term)")
    }
  }

  override func alarms() async throws -> [Alarm] {
    let jobs = try await client.pimpGetParsed(Endpoints.ALARMS, to: [AlarmJson<AlarmJob>].self)
    return jobs.map { $0.asAlarm() }
  }

  override func saveAlarm(_ alarm: Alarm) async throws -> HttpResponse {
    try await client.pimpPost(
      Endpoints.ALARMS, payload: SaveAlarm(ap: alarm.asJson(), enabled: alarm.enabled))
  }

  override func deleteAlarm(_ id: AlarmID) async throws -> HttpResponse {
    try await alarmsPost(DeleteAlarm(id: id))
  }

  override func stopAlarm() async throws -> HttpResponse {
    try await alarmsPost(SimpleCommand(cmd: JsonKeys.STOP))
  }

  override func registerNotifications(_ token: PushToken, tag: String) async throws -> HttpResponse
  {
    try await alarmsPost(RegisterPush(id: token, tag: tag))
  }

  override func unregisterNotifications(_ tag: String) async throws -> HttpResponse {
    try await alarmsPost(UnregisterPush(id: tag))
  }

  fileprivate func alarmsPost<T: Encodable>(_ payload: T) async throws -> HttpResponse {
    try await client.pimpPost(Endpoints.ALARMS, payload: payload)
  }
}
