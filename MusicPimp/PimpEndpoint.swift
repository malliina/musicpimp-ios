import Foundation

class PimpEndpoint: BasePlayer {
  let log = LoggerFactory.shared.pimp(PimpEndpoint.self)
  let endpoint: Endpoint
  let client: PimpHttpClient

  init(endpoint: Endpoint, client: PimpHttpClient) {
    self.endpoint = endpoint
    self.client = client
  }

  func postDict<T: Encodable>(_ json: T) async {
    do {
      let t = try await client.pimpPost(Endpoints.PLAYBACK, payload: json)
    } catch {
      log.info("Player error: \(error.message)")
    }
  }
}
