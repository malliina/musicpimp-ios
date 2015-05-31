//
//  PimpTableController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PimpTableController: BaseTableController {
    var player: PlayerType { get { return PlayerManager.sharedInstance.active } }
    var library: LibraryType { get { return LibraryManager.sharedInstance.active } }
}