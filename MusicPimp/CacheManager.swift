//
//  CacheManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/08/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

// see https://github.com/malliina/util-android/blob/master/src/main/scala/com/mle/file/DiskHelpers.scala
class CacheManager {
    let folder: Directory
    //let maxSize: StorageSize
    let throttler: Throttler
    let shovelSize: StorageSize = StorageSize(megs: 500)
    
    init(folder: Directory) {
        self.folder = folder
        //self.maxSize = maxSize
        self.throttler = Throttler(interval: 1.hours)
    }
    
    func maintainDiskSpace(maxSize: StorageSize) {
        throttler.throttled { () -> Void in
            self.defaultCleanup(maxSize)
        }
    }
    func defaultCleanup(maxSize: StorageSize) {
        cleanup(folder, maxSize: maxSize, shovelSize: shovelSize)
    }
    func cleanup(dir: Directory, maxSize: StorageSize, shovelSize: StorageSize) {
        let currentSize = Files.sharedInstance.folderSize(dir.url)
        let sizeDiff = currentSize - maxSize
        let needsCleanup = sizeDiff.bytes > 0
        if needsCleanup {
            free(dir, amount: shovelSize)
        }
    }
    func free(dir: Directory, amount: StorageSize) -> StorageSize {
        return dir.contents().paths.foldLeft(StorageSize.Zero) { (deleted, path) -> StorageSize in
            if deleted >= amount {
                return deleted
            } else {
                if let dir = path as? Directory {
                    return deleted + self.free(dir, amount: amount - deleted)
                } else {
                    if let file = path as? File {
                        let fileSize = file.size
                        let isDeleteSuccess = Files.sharedInstance.delete(file)
                        if isDeleteSuccess {
                            return deleted + fileSize
                        } else {
                            return deleted
                        }
                    } else {
                        return deleted
                    }
                }
            }
        }
    }
}
