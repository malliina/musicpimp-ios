//
//  PlayerSettingController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PlayerSettingController: EndpointSelectController {
    let manager = PlayerManager.sharedInstance
    
    override func use(endpoint: Endpoint) {
        let _ = manager.use(endpoint: endpoint)
    }
    
    override func loadActive() -> Endpoint {
        return manager.loadActive()
    }
}
