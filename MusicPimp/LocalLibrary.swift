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

class LocalLibrary: BaseLibrary, LibraryType {
    static let sharedInstance = LocalLibrary()
    
    static let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as! String
    override var isLocal: Bool { get { return true } }
    let supportedExtensions = ["mp3"]
    
    let musicRootPath = documentsPath.stringByAppendingString("/music")
    
    static let ARTIST = "TPE1", ALBUM = "TALB", TRACK = "TIT2", TRACK_INDEX = "TRCK", YEAR = "TYER", GENRE = "TCON"
    
    static let rootFolderName = "music"
    
    let fileManager = NSFileManager.defaultManager()
    
    func parseTrack(absolutePath: String) -> Track? {
        let attrs: NSDictionary? = fileManager.attributesOfItemAtPath(absolutePath, error: nil)
        if let sizeNum = attrs?.objectForKey(NSFileSize) as? NSNumber {
            let size = sizeNum.longLongValue
            let url = NSURL(fileURLWithPath: absolutePath)
            if let asset = AVAsset.assetWithURL(url) as? AVAsset {
                var artist: String? = nil
                var album: String? = nil
                var track: String? = nil
                if let metas = asset.metadata as? [AVMetadataItem] {
                    for meta in metas {
                        let value = meta.stringValue
                        switch meta.key.description {
                        case LocalLibrary.ARTIST:
                            artist = value
                            break
                        case LocalLibrary.ALBUM:
                            album = value
                            break
                        case LocalLibrary.TRACK:
                            track = value
                            break
                        default:
                            break
                        }
                    }
                }
                
                let relativePath = relativize(absolutePath)
                if let artist = artist {
                    if let album = album {
                        if let track = track {
                            if let dur = duration(asset) {
                                if let url = url {
                                    return Track(id: Util.urlEncode(relativePath), title: track, album: album, artist: artist, duration: Int(dur), path: relativePath, size: size, url: url, username: "", password: "")
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func parseFolder(absolute: String) -> Folder {
        let path = relativize(absolute)
        //Log.info("Abs: \(absolute), relative: \(path)")
        return Folder(id: Util.urlEncode(path), title: path.lastPathComponent, path: path)
    }
    func relativize(path: String) -> String {
        let startIdx = count(musicRootPath) + 1
        if(count(path) > startIdx) {
            let from = advance(path.startIndex, startIdx)
            return path.substringFromIndex(from)
        } else {
            return path
        }
    }
    
    func duration(asset: AVAsset) -> Float? {
        let time = asset.duration
        let secs = CMTimeGetSeconds(time)
        if(secs.isNormal) {
            return Float(secs)
        }
        return nil
    }
    
    func pingAuth(onError: PimpError -> Void, f: Version -> Void) {
        f(Version(version: "1.0.0"))
    }
    
    func tracks(id: String, onError: PimpError -> Void, f: [Track] -> Void) {
        f([])
    }
    func folder(id: String, onError: PimpError -> Void, f: MusicFolder -> Void) {
        let path = Util.urlDecode(id)
        let folder = parseFolder(path)
        //Log.info("ID: \(id)")
        folderAtPath(folder, f: f)
    }
    func isSupportedFile(path: String) -> Bool {
        return supportedExtensions.exists({ path.hasSuffix($0) })
    }
    func isNotDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileManager.fileExistsAtPath(path, isDirectory: &isDirectory)
        if !exists {
            Log.info("Path does not exist: \(path)")
        }
        return !isDirectory
    }
    func rootFolder(onError: PimpError -> Void, f: MusicFolder -> Void) {
        folderAtPath(Folder.root, f: f)
    }
    func folderAtPath(folder: Folder, f: MusicFolder -> Void) {
        let absolutePath = folder.path == Folder.root.path ? musicRootPath : musicRootPath.stringByAppendingString("/" + folder.path)
        let items: [String] = fileManager.contentsOfDirectoryAtPath(absolutePath, error: nil) as? [String] ?? []
        let paths = items.map({ absolutePath.stringByAppendingString("/" + $0) })
        var isDirectory: ObjCBool = false
        let (files, directories) = paths.partition(isNotDirectory)
        let folders = directories.map(parseFolder)
        let tracks = files.filter(isSupportedFile).flatMapOpt(parseTrack)
        //Log.info("Dir count at \(folder.path): \(directories.count), file count: \(files.count)")
        f(MusicFolder(folder: folder, folders: folders, tracks: tracks))
    }

    func urlFor(trackID: String) -> NSURL {
       return NSURL(string: "http://www.google.com")!
    }
}
