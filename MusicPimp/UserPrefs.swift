import Foundation

// Wrapper for Strings because Encodable cannot encode a primitive String
struct PimpString: Codable {
  let value: String

  init(_ value: String) {
    self.value = value
  }
}

struct Wrapped<T: Codable>: Codable {
  let value: T
  init(_ value: T) {
    self.value = value
  }
}

class UserPrefs: Persistence {
  let log = LoggerFactory.shared.system(UserPrefs.self)
  static let sharedInstance = UserPrefs()

  let prefs = UserDefaults.standard

  @Published var changes: Setting?

  let encoder = JSONEncoder()
  let decoder = JSONDecoder()

  func save<T: Encodable>(_ contents: T, key: String) -> ErrorMessage? {
    do {
      let encoded = try encoder.encode(contents)
      guard let asString = String(data: encoded, encoding: .utf8) else {
        return ErrorMessage("Unable to encode data for key '\(key)' to String.")
      }
      prefs.set(asString, forKey: key)
      changes = Setting(key: key, contents: asString)
      return nil
    } catch {
      return ErrorMessage("Unable to encode to key '\(key)'. \(error)")
    }
  }

  func load<T: Decodable>(_ key: String, _ t: T.Type) -> T? {
    guard let asString = prefs.string(forKey: key), let data = asString.data(using: .utf8) else {
      return nil
    }
    return try? decoder.decode(t, from: data)
  }
}

struct Setting {
  let key: String
  let contents: String
}
