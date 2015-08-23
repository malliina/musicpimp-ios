//
//  CacheManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/08/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

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
        Files.sharedInstance.folderSize(dir.url)
    }
    func free(dir: Directory, amount: StorageSize) -> StorageSize {
        return StorageSize.Zero
    }
}
