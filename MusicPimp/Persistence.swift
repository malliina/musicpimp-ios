import Foundation

protocol Persistence {
  var changes: Setting? { get }

  func save<T: Encodable>(_ contents: T, key: String) -> ErrorMessage?

  func load<T: Decodable>(_ key: String, _ t: T.Type) -> T?
}

extension Persistence {
  func loadBool(_ key: String) -> Bool? {
    load(key, Wrapped<Bool>.self)?.value
  }

  func loadString(_ key: String) -> String? {
    load(key, Wrapped<String>.self)?.value
  }

  func saveString(_ contents: String, key: String) -> ErrorMessage? {
    save(Wrapped<String>(contents), key: key)
  }

  func saveBool(_ contents: Bool, key: String) -> ErrorMessage? {
    save(Wrapped<Bool>(contents), key: key)
  }
}
