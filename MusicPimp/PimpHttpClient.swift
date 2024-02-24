import Foundation
import RxSwift

class Endpoints {
  static let
    PING = "/ping",
    PING_AUTH = "/pingauth",
    FOLDERS = "/folders",
    PLAYBACK = "/playback",
    WS_PLAYBACK = "/ws/playback",
    SEARCH = "/search",
    PLAYLISTS = "/playlists",
    PLAYLIST = "/playlist",
    PLAYLIST_DELETE = "/playlists/delete",
    ALARMS = "/alarms",
    ALARMS_ADD = "/alarms/editor/add",
    Popular = "/player/popular",
    Recent = "/player/recent"
}

class PimpHttpClient: HttpClient {
  private let log = LoggerFactory.shared.pimp(PimpHttpClient.self)
  let baseURL: URL
  let defaultHeaders: [String: String]
  let postHeaders: [String: String]

  static let PIMP_VERSION_18 = "application/vnd.musicpimp.v18+json"

  init(baseURL: URL, authValue: String) {
    self.baseURL = baseURL
    let headers = [
      HttpClient.AUTHORIZATION: authValue,
      HttpClient.ACCEPT: PimpHttpClient.PIMP_VERSION_18,
    ]
    self.defaultHeaders = headers
    var postHeaders = headers
    postHeaders.updateValue(HttpClient.JSON, forKey: HttpClient.CONTENT_TYPE)
    self.postHeaders = postHeaders
  }

  func pingAuth() -> Single<Version> {
    return pimpGetParsed(Endpoints.PING_AUTH, to: Version.self)
  }

  func pimpGetParsed<T: Decodable>(_ resource: String, to: T.Type) -> Single<T> {
    let req = buildGet(url: urlTo(resource), headers: defaultHeaders)
    return executeParsed(req, to: to)
  }

  func pimpPostParsed<W: Encodable, R: Decodable>(_ resource: String, payload: W, to: R.Type)
    -> Single<R>
  {
    return pimpPost(resource, payload: payload).flatMap { response in
      self.recovered { () -> R in
        try response.decode(to)
      }
    }
  }

  func pimpPostEmpty(_ resource: String) -> Single<HttpResponse> {
    let req = buildRequest(url: urlTo(resource), httpMethod: HttpClient.POST, headers: postHeaders)
    return executeChecked(req)
  }

  func pimpPost<T: Encodable>(_ resource: String, payload: T) -> Single<HttpResponse> {
    let encoder = JSONEncoder()
    do {
      let body = try encoder.encode(payload)
      let req = buildRequestWithBody(
        url: urlTo(resource), httpMethod: HttpClient.POST, headers: postHeaders, body: body)
      return executeChecked(req)
    } catch let err {
      return Single.error(err)
    }
  }

  func urlTo(_ resource: String) -> URL {
    URL(string: resource, relativeTo: baseURL)!
  }

  func onRequestError(_ data: Data, error: NSError) {
    log.error("Error: \(data)")
  }

  func onMusicFolder(_ f: MusicFolder) {
    log.info("Tracks: \(f.tracks.count)")
  }
}
