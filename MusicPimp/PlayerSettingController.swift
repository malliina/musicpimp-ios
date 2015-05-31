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
    override var manager: EndpointManager { get { return PlayerManager.sharedInstance } }
}
