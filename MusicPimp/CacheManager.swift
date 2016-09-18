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
        self.throttler = Throttler(interval: 1.hours)
    }
    
    func maintainDiskSpace(_ maxSize: StorageSize) -> StorageSize {
        let amountDeleted = throttler.throttled { () -> StorageSize in
            self.defaultCleanup(maxSize)
        }
        return amountDeleted ?? StorageSize.Zero
    }
    func defaultCleanup(_ maxSize: StorageSize) -> StorageSize {
        return cleanup(folder, maxSize: maxSize, shovelSize: shovelSize)
    }
    
    /// Ensures that dir is at most maxSize large; deleting files indiscriminately if necessary to free disk space.
    ///
    /// - parameter dir: the root dir
    /// - parameter maxSize: the maximum allowed size of dir
    /// - parameter shovelSize: the minumum amount to delete from dir if its size exceeds maxSize
    ///
    /// :return: the amount acutally deleted
    func cleanup(_ dir: Directory, maxSize: StorageSize, shovelSize: StorageSize) -> StorageSize {
        let currentSize = Files.sharedInstance.folderSize(dir.url)
        let sizeDiff = currentSize - maxSize
        let needsCleanup = sizeDiff.bytes > 0
        if needsCleanup {
            Log.info("Local cache size \(currentSize) exceeds the maximum limit of \(maxSize) by \(sizeDiff), deleting tracks...")
            var shovel = shovelSize
            if sizeDiff > shovel {
                shovel = sizeDiff
            }
            let amountDeleted = free(dir, amount: shovel)
            Log.info("Deleted \(amountDeleted) of cached tracks")
            return amountDeleted
        } else {
            return StorageSize.Zero
        }
    }
    
    /// Frees up amount from dir by deleting files.
    ///
    ///
    /// - parameter dir: the root directory to clean up
    /// - parameter amount: the amount to delete, approximately
    ///
    /// - returns: the amount actually deleted
    func free(_ dir: Directory, amount: StorageSize) -> StorageSize {
        return dir.contents().paths.foldLeft(StorageSize.Zero) { (deleted, path) -> StorageSize in
            let hasDeletedEnough = deleted >= amount
            if hasDeletedEnough {
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
