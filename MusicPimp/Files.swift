//
//  Files.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Path {
    let url: NSURL
    init(url: NSURL) {
        self.url = url
    }
    var isDirectory: Bool { return url.isDirectory }
    var isFile: Bool { return url.isFile }
    var name: String { return url.name }
}
class File: Path {
    var size: StorageSize {
        let bytes = Files.numberKey(url, key: NSURLFileSizeKey) ?? 0
        return bytes.unsignedLongLongValue.bytes
    }
    static func fromPath(absolutePath: String) -> File? {
        if let url = NSURL(fileURLWithPath: absolutePath) {
            return File(url: url)
        } else {
            return nil
        }
    }
}
class FolderContents {
    let folders: [Path]
    let files: [File]
    init(folders: [Path], files: [File]) {
        self.folders = folders
        self.files = files
    }
}

extension NSURL {
    var isDirectory: Bool {
        return Files.booleanKey(self, key: NSURLIsDirectoryKey)
    }
    var isFile: Bool {
        return Files.booleanKey(self, key: NSURLIsRegularFileKey)
    }
    var name: String {
        return Files.localize(self)
    }
}

class Files {
    static let sharedInstance = Files()
    
    static let manager = NSFileManager.defaultManager()
    static let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    
    static func localize(url: NSURL) -> String {
        var nameResult: AnyObject? = nil
        url.getResourceValue(&nameResult, forKey: NSURLLocalizedNameKey, error: nil)
        return nameResult as! String
    }
    static func numberKey(url: NSURL, key: String) -> NSNumber? {
        var numberResult: AnyObject? = nil
        url.getResourceValue(&numberResult, forKey: key, error: nil)
        return numberResult as? NSNumber
    }
    static func booleanKey(url: NSURL, key: String) -> Bool {
        return numberKey(url, key: key)?.boolValue ?? false
    }
    static func exists(path: String) -> Bool {
        return manager.fileExistsAtPath(path)
    }
    static func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        manager.fileExistsAtPath(path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
    func fileSize(absolutePath: String) -> StorageSize? {
        let attrs: NSDictionary? = Files.manager.attributesOfItemAtPath(absolutePath, error: nil)
        if let sizeNum = attrs?.objectForKey(NSFileSize) as? NSNumber {
            let size = sizeNum.unsignedLongLongValue.bytes
        }
        return nil
    }
    func folderSize(dir: String) -> StorageSize {
        let files = enumerateFiles(dir, recursive: true)
        if let files = files {
            var acc = StorageSize.Zero
            for file in files {
                if let url = file as? NSURL {
                    let summed = acc + File(url: url).size
                    acc = summed
                }
            }
            return acc
        } else {
            return StorageSize.Zero
        }
    }
    func listContents(dir: String) -> FolderContents {
        let urls = listPathsAsURLs(dir)
        let (folders, files) = urls.partition({ $0.isDirectory })
        let dirs = folders.map({ (url) -> Path in Path(url: url) })
        let fs = files.map({ (url) -> File in File(url: url) })
        return FolderContents(folders: dirs, files: fs)
    }
    func listPathsAsURLs(dir: String) -> [NSURL] {
        return enumeratePaths(dir, recursive: false)?.allObjects as? [NSURL] ?? []
    }
    func enumerateFiles(dir: String, recursive: Bool = false) -> NSDirectoryEnumerator? {
        return enumeratePaths(dir, keys: [NSURLIsRegularFileKey], recursive: recursive)
    }
    func enumerateDirectories(dir: String) -> NSDirectoryEnumerator? {
        return enumeratePaths(dir, keys: [NSURLIsDirectoryKey], recursive: false)
    }
    func enumeratePaths(dir: String, recursive: Bool = false) -> NSDirectoryEnumerator? {
        let keys = [NSURLIsDirectoryKey, NSURLIsRegularFileKey]
        return enumeratePaths(dir, keys: keys, recursive: recursive)
    }
    func enumeratePaths(dir: String, keys: [String], recursive: Bool = false) -> NSDirectoryEnumerator? {
        let options = recursive ? NSDirectoryEnumerationOptions.allZeros : NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants
        return enumeratePathsBase(dir, keys: keys, options: options)
    }
    func enumeratePathsBase(dir: String, keys: [String], options: NSDirectoryEnumerationOptions) -> NSDirectoryEnumerator? {
        let url: NSURL = Util.url(dir)
        return Files.manager.enumeratorAtURL(url, includingPropertiesForKeys: keys, options: options) { (url, err) -> Bool in
            return true
        }
    }

}



