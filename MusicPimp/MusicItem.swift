//
//  MusicItem.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 01/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class MusicItem {
    let id: String
    let title: String
    
    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
