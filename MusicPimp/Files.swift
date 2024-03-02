import Foundation

class Path {
  let url: URL

  init(url: URL) {
    self.url = url
  }

  var isDirectory: Bool { url.isDirectory }
  var isFile: Bool { url.isFile }
  var name: String { url.name }
  var lastModified: Date? { Files.lastModified(url) }
  var lastAccessed: Date? { Files.lastAccessed(url) }
}

class Directory: Path {
  var size: StorageSize { calculateSize() }

  func calculateSize() -> StorageSize {
    Files.sharedInstance.folderSize(url)
  }

  func contents() -> FolderContents {
    Files.sharedInstance.listContents(url)
  }
}

class File: Path {
  lazy var size: StorageSize = self.calculateSize()

  fileprivate func calculateSize() -> StorageSize {
    let bytes = Files.numberKey(url, key: URLResourceKey.fileSizeKey.rawValue) ?? 0
    return bytes.uint64Value.bytes
  }

  static func fromPath(_ absolutePath: String) -> File {
    File(url: URL(fileURLWithPath: absolutePath))
  }
}

class FolderContents {
  let folders: [Directory]
  let files: [File]
  lazy var paths: [Path] = self.allPaths()

  init(folders: [Directory], files: [File]) {
    self.folders = folders
    self.files = files
  }

  fileprivate func allPaths() -> [Path] {
    let folderPaths: [Path] = folders
    let filePaths: [Path] = files
    return folderPaths + filePaths
  }
}

extension URL {
  var isDirectory: Bool {
    Files.booleanKey(self, key: URLResourceKey.isDirectoryKey.rawValue)
  }
  var isFile: Bool {
    Files.booleanKey(self, key: URLResourceKey.isRegularFileKey.rawValue)
  }
  var name: String {
    Files.localize(self)
  }
}

class Files {
  static let log = LoggerFactory.shared.base("Files", category: Files.self)
  static let sharedInstance = Files()

  static let manager = FileManager.default
  static let documentsPath = NSSearchPathForDirectoriesInDomains(
    .documentDirectory, .userDomainMask, true)[0]

  static func localize(_ url: URL) -> String {
    resourceValue(url, key: URLResourceKey.localizedNameKey.rawValue)!
  }

  static func lastAccessed(_ url: URL) -> Date? {
    resourceValue(url, key: URLResourceKey.contentAccessDateKey.rawValue)
  }

  static func lastModified(_ url: URL) -> Date? {
    resourceValue(url, key: URLResourceKey.contentModificationDateKey.rawValue)
  }

  static func booleanKey(_ url: URL, key: String) -> Bool {
    numberKey(url, key: key)?.boolValue ?? false
  }

  static func numberKey(_ url: URL, key: String) -> NSNumber? {
    resourceValue(url, key: key)
  }

  static func resourceValue<T>(_ url: URL, key: String) -> T? {
    var res: AnyObject? = nil
    do {
      try (url as NSURL).getResourceValue(&res, forKey: URLResourceKey(rawValue: key))
    } catch _ {
    }
    return res as? T
  }

  static func exists(_ path: String) -> Bool {
    return manager.fileExists(atPath: path)
  }

  static func isDirectory(_ path: String) -> Bool {
    var isDirectory: ObjCBool = false
    manager.fileExists(atPath: path, isDirectory: &isDirectory)
    return isDirectory.boolValue
  }

  func delete(_ file: File) -> Bool {
    delete(file.url)
  }

  func delete(_ url: URL) -> Bool {
    do {
      try Files.manager.removeItem(at: url)
      return true
    } catch _ {
      return false
    }
  }

  func fileSize(_ absolutePath: String) -> StorageSize? {
    let attrs: [FileAttributeKey: Any]? = try? Files.manager.attributesOfItem(atPath: absolutePath)
    let maybeSize = attrs?[FileAttributeKey.size]
    if let sizeNum = maybeSize as? NSNumber {
      let size = sizeNum.uint64Value.bytes
      return size
    }
    return nil
  }

  func folderSize(_ dir: URL) -> StorageSize {
    let files = enumerateFiles(dir, recursive: true)
    if let files = files {
      var acc = StorageSize.Zero
      for file in files {
        if let url = file as? URL {
          let summed = acc + File(url: url).size
          acc = summed
        }
      }
      return acc
    } else {
      Files.log.info("Unable to determine size of directory at URL \(dir)")
      return StorageSize.Zero
    }
  }

  func listContents(_ dir: URL) -> FolderContents {
    let urls = listPathsAsURLs(dir)
    let (folders, files) = urls.partition({ $0.isDirectory })
    let dirs = folders.map { (url) -> Directory in Directory(url: url) }
    let fs = files.map({ (url) -> File in File(url: url) })
    return FolderContents(folders: dirs, files: fs)
  }

  func listPathsAsURLs(_ dir: URL) -> [URL] {
    enumeratePaths(dir, recursive: false)?.allObjects as? [URL] ?? []
  }

  func enumerateFiles(_ dir: URL, recursive: Bool = false) -> FileManager.DirectoryEnumerator? {
    enumeratePaths(dir, keys: [URLResourceKey.isRegularFileKey], recursive: recursive)
  }

  func enumerateDirectories(_ dir: URL) -> FileManager.DirectoryEnumerator? {
    enumeratePaths(dir, keys: [URLResourceKey.isDirectoryKey], recursive: false)
  }

  func enumeratePaths(_ dir: URL, recursive: Bool = false) -> FileManager.DirectoryEnumerator? {
    let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.isRegularFileKey]
    return enumeratePaths(dir, keys: keys, recursive: recursive)
  }

  func enumeratePaths(_ dir: URL, keys: [URLResourceKey], recursive: Bool = false) -> FileManager
    .DirectoryEnumerator?
  {
    let options =
      recursive
      ? FileManager.DirectoryEnumerationOptions()
      : FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants
    return enumeratePathsBase(dir, keys: keys, options: options)
  }

  func enumeratePathsBase(
    _ dir: URL, keys: [URLResourceKey], options: FileManager.DirectoryEnumerationOptions
  ) -> FileManager.DirectoryEnumerator? {
    if dir.isDirectory {
      return Files.manager.enumerator(at: dir, includingPropertiesForKeys: keys, options: options) {
        (url, err) -> Bool in
        return true
      }
    } else {
      return nil
    }
  }

}
