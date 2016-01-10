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
    static let sharedInstance = LocalLibrary()
    static let currentVersion = Version(version: "1.0.0")
    static let documentsPath = Files.documentsPath
    static let ARTIST = "TPE1", ALBUM = "TALB", TRACK = "TIT2", TRACK_INDEX = "TRCK", YEAR = "TYER", GENRE = "TCON"
    static let rootFolderName = "music"
    
    override var isLocal: Bool { get { return true } }
    
    let supportedExtensions = ["mp3"]
    
    let fileManager = NSFileManager.defaultManager()
    
    let musicRootPath = documentsPath.stringByAppendingString("/music")
    
    var musicRootURL: NSURL { get { return Util.url(self.musicRootPath) } }
    
    var size: StorageSize { return Files.sharedInstance.folderSize(musicRootURL) }
    
    func contains(track: Track) -> Bool {
        return url(track) != nil
    }
    
    func url(track: Track) -> NSURL? {
        let path = track.path
        let absolutePath = pathTo(path)
        if Files.exists(absolutePath) {
            let attrs: NSDictionary? = try? fileManager.attributesOfItemAtPath(absolutePath)
            if let sizeNum = attrs?.objectForKey(NSFileSize) as? NSNumber, localStorageSize = StorageSize.fromBytes(sizeNum.longLongValue) {
                let trackSize = track.size
                if trackSize == localStorageSize {
                    Log.info("Found local track at \(path)")
                    return NSURL(fileURLWithPath: absolutePath)
                } else {
                    Log.info("Local size of \(localStorageSize) does not match track size of \(trackSize), ignoring local")
                }
            } else {
                Log.error("Unable to get file size for \(path)")
            }
        } else {
            Log.info("Local track not found for \(path)")
        }
        return nil
    }
    
    func pathTo(relativePath: String) -> String {
        return self.musicRootPath + "/" + relativePath.stringByReplacingOccurrencesOfString("\\", withString: "/")
    }

    func deleteContents() -> Bool {
        let deleteSuccess: Bool
        do {
            try fileManager.removeItemAtPath(musicRootPath)
            deleteSuccess = true
        } catch _ {
            deleteSuccess = false
        }
        let dirRecreateSuccess: Bool
        do {
            try self.fileManager.createDirectoryAtPath(musicRootPath, withIntermediateDirectories: true, attributes: nil)
            dirRecreateSuccess = true
        } catch _ {
            dirRecreateSuccess = false
        }
        contentsUpdated.raise(nil)
        return deleteSuccess && dirRecreateSuccess
    }
    
    func parseTrack(absolutePath: String) -> Track? {
        let attrs: NSDictionary? = try? fileManager.attributesOfItemAtPath(absolutePath)
        if let sizeNum = attrs?.objectForKey(NSFileSize) as? NSNumber, size = StorageSize.fromBytes(sizeNum.longLongValue) {
            let url = NSURL(fileURLWithPath: absolutePath)
            let asset = AVAsset(URL: url)
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
                return Track(id: Util.urlEncode(relativePath), title: actualTrack, album: actualAlbum, artist: actualArtist, duration: dur, path: relativePath, size: size, url: url)
            } else {
                Log.error("Unable to parse duration and URL of \(absolutePath)")
            }
            
        } else {
            Log.error("Unable to determine file size of \(absolutePath)")
        }
        return nil
    }
    
    func parseFolder(absolute: String) -> Folder {
        let path = relativize(absolute)
        //Log.info("Abs: \(absolute), relative: \(path)")
        return Folder(id: Util.urlEncode(path), title: path.lastPathComponent(), path: path)
    }
    
    func relativize(path: String) -> String {
        let startIdx = musicRootPath.characters.count + 1
        if(path.characters.count > startIdx) {
            let from = path.startIndex.advancedBy(startIdx)
            return path.substringFromIndex(from)
        } else {
            return path
        }
    }
    
    func duration(asset: AVAsset) -> Duration? {
        let time = asset.duration
        let secs = CMTimeGetSeconds(time)
        if(secs.isNormal) {
            return secs.seconds
        }
        return nil
    }
    
    override func pingAuth(onError: PimpError -> Void, f: Version -> Void) {
        f(LocalLibrary.currentVersion)
    }
    
    override func folder(id: String, onError: PimpError -> Void, f: MusicFolder -> Void) {
        let path = Util.urlDecode(id)
        let folder = parseFolder(path)
        //Log.info("ID: \(id)")
        folderAtPath(folder, f: f)
    }
    
    func isSupportedFile(path: String) -> Bool {
        return supportedExtensions.exists({ path.hasSuffix($0) })
    }
    
    override func rootFolder(onError: PimpError -> Void, f: MusicFolder -> Void) {
        folderAtPath(Folder.root, f: f)
    }
    
    func folderAtPath(folder: Folder, f: MusicFolder -> Void) {
        let absolutePath = folder.path == Folder.root.path ? musicRootPath : musicRootPath.stringByAppendingString("/" + folder.path)
        let items: [String] = (try? fileManager.contentsOfDirectoryAtPath(absolutePath)) ?? []
        let paths = items.map({ absolutePath.stringByAppendingString("/" + $0) })
        let (directories, files) = paths.partition(Files.isDirectory)
        let folders = directories.map(parseFolder)
        let tracks = files.filter(isSupportedFile).flatMapOpt(parseTrack)
        //Log.info("Dir count at \(folder.path): \(directories.count), file count: \(files.count)")
        f(MusicFolder(folder: folder, folders: folders, tracks: tracks))
    }
}
