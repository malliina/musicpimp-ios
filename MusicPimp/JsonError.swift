import Foundation

enum JsonError: Error {
  case notJson(Data)
  case missing(String)
  case invalid(String, Any)

  var message: String { return JsonError.stringify(json: self) }

  static func stringify(json: JsonError) -> String {
    return switch json {
    case .missing(let key):
      "Key not found: '\(key)'."
    case .invalid(let key, let actual):
      "Invalid '\(key)' value: '\(actual)'."
    case .notJson(_):
      "Invalid response format. Expected JSON."
    }
  }
}
