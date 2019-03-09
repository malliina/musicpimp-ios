//
//  PushToken.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 03/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

struct PushToken: IdCodable {
    let token: String
    var value: String { return token }
    
    init(token: String) {
        self.token = token
    }
    
    init(id: String) {
        self.token = id
    }
}
