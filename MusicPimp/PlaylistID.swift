//
//  PlaylistID.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 02/11/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class PlaylistID: CustomStringConvertible {
    let id: Int
    
    init(id: Int) {
        self.id = id
    }
    
    public var description: String { return "\(id)" }
}
