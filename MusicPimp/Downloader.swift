import Foundation

class Downloader {
  let log = LoggerFactory.shared.network(Downloader.self)

  typealias RelativePath = String

  let fileManager = FileManager.default
  let documentsPath = NSSearchPathForDirectoriesInDomains(
    .documentDirectory, .userDomainMask, true)[0]
  let basePath: String
  let session = URLSession.shared

  init(basePath: String) {
    self.basePath = basePath
  }

  func download(_ url: URL, authValue: String?, relativePath: RelativePath, replace: Bool = false)
    async throws -> String
  {
    let destPath = pathTo(relativePath)
    if replace || !Files.exists(destPath) {
      log.info("Downloading \(url)")
      var request = URLRequest(url: url)
      if let authValue = authValue {
        request.addValue(authValue, forHTTPHeaderField: "Authorization")
      }
      let (data, response) = try await session.data(for: request)
      guard let response = response as? HTTPURLResponse else {
        throw simpleError("Unknown response.")
      }
      guard response.isSuccess else {
        throw PimpError.responseFailure(
          ResponseDetails(resource: url, code: response.statusCode, message: nil))
      }
      let dir = destPath.stringByDeletingLastPathComponent()
      guard
        (try? fileManager.createDirectory(
          atPath: dir, withIntermediateDirectories: true, attributes: nil)) != nil
      else {
        throw simpleError("Unable to create directory: \(dir)")
      }
      guard (try? data.write(to: URL(fileURLWithPath: destPath), options: [.atomic])) != nil else {
        throw simpleError("Unable to write \(destPath)")
      }
      return destPath
    } else {
      return destPath
    }
  }

  func prepareDestination(_ relativePath: RelativePath) -> String? {
    let destPath = pathTo(relativePath)
    let dir = destPath.stringByDeletingLastPathComponent()
    let dirSuccess: Bool
    do {
      try self.fileManager.createDirectory(
        atPath: dir, withIntermediateDirectories: true, attributes: nil)
      dirSuccess = true
    } catch _ {
      dirSuccess = false
    }
    return dirSuccess ? destPath : nil
  }

  func pathTo(_ relativePath: RelativePath) -> String {
    self.basePath + "/" + relativePath.replacingOccurrences(of: "\\", with: "/")
  }

  func simpleError(_ message: String) -> PimpError {
    PimpError.simpleError(ErrorMessage(message))
  }
}
