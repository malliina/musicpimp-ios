import Foundation

class HttpClient {
  private let log = LoggerFactory.shared.network(HttpClient.self)
  static let JSON = "application/json", CONTENT_TYPE = "Content-Type", ACCEPT = "Accept",
    GET = "GET", POST = "POST", AUTHORIZATION = "Authorization", BASIC = "Basic"

  static func basicAuthValue(_ username: String, password: String) -> String {
    let encodable = "\(username):\(password)"
    let encoded = encodeBase64(encodable)
    return "\(HttpClient.BASIC) \(encoded)"
  }

  static func authHeader(_ word: String, unencoded: String) -> String {
    let encoded = HttpClient.encodeBase64(unencoded)
    return "\(word) \(encoded)"
  }

  static func encodeBase64(_ unencoded: String) -> String {
    unencoded.data(using: String.Encoding.utf8)!.base64EncodedString(
      options: NSData.Base64EncodingOptions())
  }

  let session = URLSession.shared

  func executeParsed<T: Decodable>(_ req: URLRequest, to: T.Type) async throws -> T {
    let checked = try await executeChecked(req)
    return try checked.decode(to)
  }

  func executeChecked(_ req: URLRequest) async throws -> HttpResponse {
    // Fix
    let url = req.url ?? URL(string: "https://www.musicpimp.org")!
    let response = try await executeHttp(req)
    return try statusChecked(url, response: response)
  }

  func executeHttp(_ req: URLRequest) async throws -> HttpResponse {
    let (data, response) = try await session.data(for: req)
    if let response = response as? HTTPURLResponse {
      return HttpResponse(http: response, data: data)
    } else {
      throw PimpError.simple(
        "Non-HTTP response received from \(req.url?.absoluteString ?? "no url").")
    }
  }

  func statusChecked(_ url: URL, response: HttpResponse) throws -> HttpResponse {
    if response.isStatusOK {
      return response
    } else {
      self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
      let errorMessage = try? response.decode(FailReason.self).reason
      throw PimpError.responseFailure(
        ResponseDetails(resource: url, code: response.statusCode, message: errorMessage))
    }
  }

  func buildGet(url: URL, headers: [String: String] = [:]) -> URLRequest {
    buildRequest(url: url, httpMethod: HttpClient.GET, headers: headers)
  }

  func buildRequestWithBody(url: URL, httpMethod: String, headers: [String: String], body: Data)
    -> URLRequest
  {
    var req = buildRequest(url: url, httpMethod: httpMethod, headers: headers)
    req.httpBody = body
    return req
  }

  func buildRequest(url: URL, httpMethod: String, headers: [String: String]) -> URLRequest {
    var req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5)
    req.httpMethod = httpMethod
    for (key, value) in headers {
      req.addValue(value, forHTTPHeaderField: key)
    }
    return req
  }
}

struct FailReason: Codable {
  let reason: String
}
