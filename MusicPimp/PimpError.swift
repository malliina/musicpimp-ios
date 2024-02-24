import Foundation

enum PimpError: Error {
  case parseError(JsonError)
  case responseFailure(ResponseDetails)
  case networkFailure(RequestFailure)
  case simpleError(ErrorMessage)

  var message: String { return PimpError.stringify(error: self) }

  static func simple(_ message: String) -> PimpError {
    PimpError.simpleError(ErrorMessage(message))
  }

  static func stringify(error: PimpError) -> String {
    switch error {
    case .parseError(let json):
      return JsonError.stringify(json: json)
    case .responseFailure(let details):
      let code = details.code
      switch code {
      case 400:  // Bad Request
        return "A network request was rejected."
      case 401:
        return "Check your username/password."
      case 404:
        return "Resource not found: \(details.resource)."
      default:
        if let message = details.message {
          return "Error code: \(code), message: \(message)"
        } else {
          return "Error code: \(code)."
        }
      }
    case .networkFailure(_):
      return "A network error occurred."
    case .simpleError(let message):
      return message.message
    }
  }
}

class PimpErrorUtil {
  static func stringifyDetailed(_ error: PimpError) -> String {
    return switch error {
    case .networkFailure(let request):
      "Unable to connect to \(request.url.description), status code \(request.code)."
    default:
      error.message
    }
  }
}

class ResponseDetails {
  let resource: URL
  let code: Int
  let message: String?

  init(resource: URL, code: Int, message: String?) {
    self.resource = resource
    self.code = code
    self.message = message
  }
}

class RequestFailure {
  let url: URL
  let code: Int
  let data: Data?

  init(url: URL, code: Int, data: Data?) {
    self.url = url
    self.code = code
    self.data = data
  }
}

struct ErrorMessage {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}
