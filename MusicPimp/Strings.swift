import Foundation

extension String {
  func startsWith(_ str: String) -> Bool {
    self.hasPrefix(str)
  }

  func endsWith(_ str: String) -> Bool {
    self.hasSuffix(str)
  }

  func contains(_ str: String) -> Bool {
    self.range(of: str) == nil
  }

  func head() -> Character {
    self[self.startIndex]
  }

  func tail() -> String {
    String(self.dropFirst())
  }

  func lastPathComponent() -> String {
    (self as NSString).lastPathComponent
  }

  func stringByDeletingLastPathComponent() -> String {
    (self as NSString).deletingLastPathComponent
  }

  func stringByDeletingPathExtension() -> String {
    (self as NSString).deletingPathExtension
  }

  func stringByAppendingPathComponent(_ path: String) -> String {
    (self as NSString).appendingPathComponent(path)
  }

}
