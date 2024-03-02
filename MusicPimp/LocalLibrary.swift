import AVFoundation
import AudioToolbox
import Foundation

class LocalLibrary: BaseLibrary {
  let log = LoggerFactory.shared.pimp(LocalLibrary.self)

  static let sharedInstance = LocalLibrary()
  static let currentVersion = Version(version: "1.0.0")
  static let documentsPath = Files.documentsPath
  static let artist = "TPE1", album = "TALB", track = "TIT2", trackIndex = "TRCK", year = "TYER",
    genre = "TCON"
  static let rootFolderName = "music"

  override var isLocal: Bool { true }

  override var id: String { Endpoint.Local.id }
  
  let supportedExtensions = ["mp3"]

  let fileManager = FileManager.default

  let musicRootPath = documentsPath + "/music"

  var musicRootURL: URL { return URL(fileURLWithPath: musicRootPath, isDirectory: true) }

  var size: StorageSize { return Files.sharedInstance.folderSize(musicRootURL) }

  override func pingAuth() async throws -> Version {
    LocalLibrary.currentVersion
  }

  override func folder(_ id: FolderID) async throws -> MusicFolder {
    folderAtPath(folderFor(path: id.id))
  }

  override func rootFolder() async throws -> MusicFolder {
    folderAtPath(Folder.root)
  }

  private func folderAtPath(_ folder: Folder) -> MusicFolder {
    //        log.info("Folder at \(folder.id) \(folder.title)")
    let absolutePath =
      folder.path == Folder.root.path ? musicRootPath : musicRootPath + ("/" + folder.path)
    let items: [String] = (try? fileManager.contentsOfDirectory(atPath: absolutePath)) ?? []
    let paths = items.map({ absolutePath + ("/" + $0) })
    let (directories, files) = paths.partition(Files.isDirectory)
    let folders = directories.map(parseFolder)
    let tracks = files.filter(isSupportedFile).flatMapOpt(parseTrack)
    //Log.info("Dir count at \(folder.path): \(directories.count), file count: \(files.count)")
    return MusicFolder(folder: folder, folders: folders, tracks: tracks)
  }

  func isSupportedFile(_ path: String) -> Bool {
    supportedExtensions.exists({ path.hasSuffix($0) })
  }

  func contains(_ track: Track) -> Bool {
    url(track) != nil
  }

  func url(_ track: Track) -> URL? {
    let path = track.path
    let absolutePath = pathTo(path)
    if Files.exists(absolutePath) {
      if let sizeNum = try? fileManager.attributesOfItem(atPath: absolutePath)[
        FileAttributeKey.size] as? NSNumber,
        let localStorageSize = StorageSize.fromBytes(sizeNum.int64Value)
      {
        let trackSize = track.size
        if trackSize == localStorageSize {
          log.info("Found local track at \(path)")
          return URL(fileURLWithPath: absolutePath)
        } else {
          log.info(
            "Local size of \(localStorageSize) does not match track size of \(trackSize), ignoring local"
          )
        }
      } else {
        log.error("Unable to get file size for \(path)")
      }
    } else {
      log.info("Local track not found for \(path)")
    }
    return nil
  }

  func pathTo(_ relativePath: String) -> String {
    self.musicRootPath + "/" + relativePath.replacingOccurrences(of: "\\", with: "/")
  }

  func deleteContents() async -> Bool {
    return await Task(priority: .background) {
      self.deleteContentsSync()
    }.value
  }

  private func deleteContentsSync() -> Bool {
    let deleteSuccess: Bool
    do {
      try fileManager.removeItem(atPath: musicRootPath)
      deleteSuccess = true
    } catch _ {
      deleteSuccess = false
    }
    let dirRecreateSuccess: Bool
    do {
      try self.fileManager.createDirectory(
        atPath: musicRootPath, withIntermediateDirectories: true, attributes: nil)
      dirRecreateSuccess = true
    } catch _ {
      dirRecreateSuccess = false
    }
    contentsUpdated = nil
    return deleteSuccess && dirRecreateSuccess
  }

  func parseTrack(_ absolutePath: String) -> Track? {
    let attrs: [FileAttributeKey: Any]? = try? Files.manager.attributesOfItem(atPath: absolutePath)
    //let attrs: NSDictionary? = try? fileManager.attributesOfItem(atPath: absolutePath) as NSDictionary?
    if let sizeNum = attrs?[FileAttributeKey.size] as? NSNumber,
      let size = StorageSize.fromBytes(sizeNum.int64Value)
    {
      let url = URL(fileURLWithPath: absolutePath)
      let asset = AVAsset(url: url)
      var artist: String? = nil
      var album: String? = nil
      var track: String? = nil
      let metas = asset.metadata
      // parses any tags
      for meta in metas {
        let value = meta.stringValue
        if let key = meta.key {
          switch key.description {
          case LocalLibrary.track:
            track = value
            break
          case LocalLibrary.album:
            album = value
            break
          case LocalLibrary.artist:
            artist = value
            break
          default:
            break
          }
        }
      }
      let relativePath = relativize(absolutePath)
      // falls back to filepath-based parsing
      let relativeDir = relativePath.stringByDeletingLastPathComponent()

      let actualTrack = track ?? relativePath.lastPathComponent().stringByDeletingPathExtension()
      let albumString = album ?? relativeDir.lastPathComponent()
      let actualAlbum = albumString == "/" ? "" : albumString
      let artistString =
        artist ?? relativeDir.stringByDeletingLastPathComponent().lastPathComponent()
      let actualArtist = artistString == "/" ? "" : artistString
      if let dur = duration(asset) {
        return Track(
          id: TrackID(id: relativePath), title: actualTrack, album: actualAlbum,
          artist: actualArtist, duration: dur, path: relativePath, size: size, url: url)
      } else {
        log.error("Unable to parse duration and URL of \(absolutePath)")
      }

    } else {
      log.error("Unable to determine file size of \(absolutePath)")
    }
    return nil
  }

  private func parseFolder(_ absolute: String) -> Folder {
    return folderFor(path: relativize(absolute))
  }

  private func folderFor(path: String) -> Folder {
    let p = path.startsWith("/") ? path.tail() : path
    return Folder(id: FolderID(id: p), title: path.lastPathComponent(), path: p)
  }

  func relativize(_ path: String) -> String {
    return String(path.dropFirst(musicRootPath.count))
  }

  func duration(_ asset: AVAsset) -> Duration? {
    let time = asset.duration
    let secs = CMTimeGetSeconds(time)
    if secs.isNormal {
      return secs.seconds
    }
    return nil
  }
}
