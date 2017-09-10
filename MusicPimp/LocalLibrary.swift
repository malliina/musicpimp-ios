//
//  LocalLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

class LocalLibrary: BaseLibrary {
    let log = Logger("org.musicpimp.MusicPimp.Local", category: "Library")
    
    static let sharedInstance = LocalLibrary()
    static let currentVersion = Version(version: "1.0.0")
    static let documentsPath = Files.documentsPath
    static let ARTIST = "TPE1", ALBUM = "TALB", TRACK = "TIT2", TRACK_INDEX = "TRCK", YEAR = "TYER", GENRE = "TCON"
    static let rootFolderName = "music"
    
    override var isLocal: Bool { get { return true } }
    
    let supportedExtensions = ["mp3"]
    
    let fileManager = FileManager.default
    
    let musicRootPath = documentsPath + "/music"

    var musicRootURL: URL { get { return URL(fileURLWithPath: musicRootPath, isDirectory: true) } }
    
    var size: StorageSize { return Files.sharedInstance.folderSize(musicRootURL) }
    
    func contains(_ track: Track) -> Bool {
        return url(track) != nil
    }
    
    func url(_ track: Track) -> URL? {
        let path = track.path
        let absolutePath = pathTo(path)
        if Files.exists(absolutePath) {
            if let sizeNum = try? fileManager.attributesOfItem(atPath: absolutePath)[FileAttributeKey.size] as? NSNumber,
                let size = sizeNum,
                let localStorageSize = StorageSize.fromBytes(size.int64Value) {
                let trackSize = track.size
                if trackSize == localStorageSize {
                    log.info("Found local track at \(path)")
                    return URL(fileURLWithPath: absolutePath)
                } else {
                    log.info("Local size of \(localStorageSize) does not match track size of \(trackSize), ignoring local")
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
        return self.musicRootPath + "/" + relativePath.replacingOccurrences(of: "\\", with: "/")
    }

    func deleteContents() -> Bool {
        let deleteSuccess: Bool
        do {
            try fileManager.removeItem(atPath: musicRootPath)
            deleteSuccess = true
        } catch _ {
            deleteSuccess = false
        }
        let dirRecreateSuccess: Bool
        do {
            try self.fileManager.createDirectory(atPath: musicRootPath, withIntermediateDirectories: true, attributes: nil)
            dirRecreateSuccess = true
        } catch _ {
            dirRecreateSuccess = false
        }
        contentsUpdated.raise(nil)
        return deleteSuccess && dirRecreateSuccess
    }
    
    func parseTrack(_ absolutePath: String) -> Track? {
        let attrs: [FileAttributeKey: Any]? = try? Files.manager.attributesOfItem(atPath: absolutePath)
        //let attrs: NSDictionary? = try? fileManager.attributesOfItem(atPath: absolutePath) as NSDictionary?
        if let sizeNum = attrs?[FileAttributeKey.size] as? NSNumber, let size = StorageSize.fromBytes(sizeNum.int64Value) {
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
                    case LocalLibrary.TRACK:
                        track = value
                        break
                    case LocalLibrary.ALBUM:
                        album = value
                        break
                    case LocalLibrary.ARTIST:
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
            let actualAlbum = album ?? relativeDir.lastPathComponent()
            let actualArtist = artist ?? relativeDir.stringByDeletingLastPathComponent().lastPathComponent()
                
            if let dur = duration(asset) {
                return Track(id: Util.urlEncodePathWithPlus(relativePath), title: actualTrack, album: actualAlbum, artist: actualArtist, duration: dur, path: relativePath, size: size, url: url)
            } else {
                log.error("Unable to parse duration and URL of \(absolutePath)")
            }
            
        } else {
            log.error("Unable to determine file size of \(absolutePath)")
        }
        return nil
    }
    
    func parseFolder(_ absolute: String) -> Folder {
        let path = relativize(absolute)
        //Log.info("Abs: \(absolute), relative: \(path)")
        return Folder(id: Util.urlEncodePathWithPlus(path), title: path.lastPathComponent(), path: path)
    }
    
    func relativize(_ path: String) -> String {
        let startIdx = musicRootPath.characters.count + 1
        if(path.characters.count > startIdx) {
            let from = path.characters.index(path.startIndex, offsetBy: startIdx)
            return path.substring(from: from)
        } else {
            return path
        }
    }
    
    func duration(_ asset: AVAsset) -> Duration? {
        let time = asset.duration
        let secs = CMTimeGetSeconds(time)
        if(secs.isNormal) {
            return secs.seconds
        }
        return nil
    }
    
    override func pingAuth(_ onError: @escaping (PimpError) -> Void, f: @escaping (Version) -> Void) {
        f(LocalLibrary.currentVersion)
    }
    
    override func folder(_ id: String, onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void) {
        let path = Util.urlDecodeWithPlus(id)
        let folder = parseFolder(path)
        //Log.info("ID: \(id)")
        folderAtPath(folder, f: f)
    }
    
    func isSupportedFile(_ path: String) -> Bool {
        return supportedExtensions.exists({ path.hasSuffix($0) })
    }
    
    override func rootFolder(_ onError: @escaping (PimpError) -> Void, f: @escaping (MusicFolder) -> Void) {
        folderAtPath(Folder.root, f: f)
    }
    
    func folderAtPath(_ folder: Folder, f: (MusicFolder) -> Void) {
        let absolutePath = folder.path == Folder.root.path ? musicRootPath : musicRootPath + ("/" + folder.path)
        let items: [String] = (try? fileManager.contentsOfDirectory(atPath: absolutePath)) ?? []
        let paths = items.map({ absolutePath + ("/" + $0) })
        let (directories, files) = paths.partition(Files.isDirectory)
        let folders = directories.map(parseFolder)
        let tracks = files.filter(isSupportedFile).flatMapOpt(parseTrack)
        //Log.info("Dir count at \(folder.path): \(directories.count), file count: \(files.count)")
        f(MusicFolder(folder: folder, folders: folders, tracks: tracks))
    }
}
