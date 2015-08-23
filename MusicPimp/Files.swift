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
    var lastModified: NSDate? { return Files.lastModified(url) }
    var lastAccessed: NSDate? { return Files.lastAccessed(url) }
}
class Directory: Path {
    var size: StorageSize { return calculateSize() }
    
    func calculateSize() -> StorageSize {
        return Files.sharedInstance.folderSize(url)
    }
    
    func contents() -> FolderContents {
        return Files.sharedInstance.listContents(url)
    }
}
class File: Path {
    lazy var size: StorageSize = self.calculateSize()
    
    private func calculateSize() -> StorageSize {
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
    let folders: [Directory]
    let files: [File]
    lazy var paths: [Path] = self.allPaths()
    
    init(folders: [Directory], files: [File]) {
        self.folders = folders
        self.files = files
    }
    
    private func allPaths() -> [Path] {
        let folderPaths: [Path] = folders
        let filePaths: [Path] = files
        return folderPaths + filePaths
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
        return resourceValue(url, key: NSURLLocalizedNameKey)!
    }
    static func lastAccessed(url: NSURL) -> NSDate? {
        return resourceValue(url, key: NSURLContentAccessDateKey)
    }
    static func lastModified(url: NSURL) -> NSDate? {
        return resourceValue(url, key: NSURLContentModificationDateKey)
    }
    static func booleanKey(url: NSURL, key: String) -> Bool {
        return numberKey(url, key: key)?.boolValue ?? false
    }
    static func numberKey(url: NSURL, key: String) -> NSNumber? {
        return resourceValue(url, key: key)
    }
    static func resourceValue<T>(url: NSURL, key: String) -> T? {
        var res: AnyObject? = nil
        url.getResourceValue(&res, forKey: key, error: nil)
        return res as? T
    }
    static func exists(path: String) -> Bool {
        return manager.fileExistsAtPath(path)
    }
    static func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        manager.fileExistsAtPath(path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
    func delete(file: File) -> Bool {
        return delete(file.url)
    }
    func delete(url: NSURL) -> Bool {
        return Files.manager.removeItemAtURL(url, error: nil)
    }
    func fileSize(absolutePath: String) -> StorageSize? {
        let attrs: NSDictionary? = Files.manager.attributesOfItemAtPath(absolutePath, error: nil)
        if let sizeNum = attrs?.objectForKey(NSFileSize) as? NSNumber {
            let size = sizeNum.unsignedLongLongValue.bytes
        }
        return nil
    }
    func folderSize(dir: NSURL) -> StorageSize {
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
    func listContents(dir: NSURL) -> FolderContents {
        let urls = listPathsAsURLs(dir)
        let (folders, files) = urls.partition({ $0.isDirectory })
        let dirs = folders.map({ (url) -> Directory in Directory(url: url) })
        let fs = files.map({ (url) -> File in File(url: url) })
        return FolderContents(folders: dirs, files: fs)
    }
    func listPathsAsURLs(dir: NSURL) -> [NSURL] {
        return enumeratePaths(dir, recursive: false)?.allObjects as? [NSURL] ?? []
    }
    func enumerateFiles(dir: NSURL, recursive: Bool = false) -> NSDirectoryEnumerator? {
        return enumeratePaths(dir, keys: [NSURLIsRegularFileKey], recursive: recursive)
    }
    func enumerateDirectories(dir: NSURL) -> NSDirectoryEnumerator? {
        return enumeratePaths(dir, keys: [NSURLIsDirectoryKey], recursive: false)
    }
    func enumeratePaths(dir: NSURL, recursive: Bool = false) -> NSDirectoryEnumerator? {
        let keys = [NSURLIsDirectoryKey, NSURLIsRegularFileKey]
        return enumeratePaths(dir, keys: keys, recursive: recursive)
    }
    func enumeratePaths(dir: NSURL, keys: [String], recursive: Bool = false) -> NSDirectoryEnumerator? {
        let options = recursive ? NSDirectoryEnumerationOptions.allZeros : NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants
        return enumeratePathsBase(dir, keys: keys, options: options)
    }
    func enumeratePathsBase(dir: NSURL, keys: [String], options: NSDirectoryEnumerationOptions) -> NSDirectoryEnumerator? {
        return Files.manager.enumeratorAtURL(dir, includingPropertiesForKeys: keys, options: options) { (url, err) -> Bool in
            return true
        }
    }

}



