//
//  CacheInfoController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 05/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class CacheInfoController: BaseTableController {
    var currentLimitDescription: String {
        get {
            let gigs = settings.cacheLimit.toGigs
            return "\(gigs) GB"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        run(settings.cacheLimitChanged, onResult: self.onCacheLimitChanged)
    }
    
    func onCacheLimitChanged(_ newSize: StorageSize) {
        
    }
}
