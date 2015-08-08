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
            return settings.cacheLimit.shortDescription
        }
    }
}
