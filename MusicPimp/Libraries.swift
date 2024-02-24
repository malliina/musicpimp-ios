import Foundation

class Libraries {
  static func fromEndpoint(_ e: Endpoint) -> LibraryType {
    if e.id == Endpoint.Local.id {
      return LocalLibrary.sharedInstance
    } else {
      return PimpLibrary(
        endpoint: e, client: PimpHttpClient(baseURL: e.httpBaseUrl, authValue: e.authHeader))
    }
  }
}
