//
//  SourceSettingController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class SourceSettingController: EndpointSelectController {
    override var manager: EndpointManager { get { return LibraryManager.sharedInstance } }
    override var segueID: String { get { return "MusicSource" } }
    
    var subscription: Disposable? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LibraryManager.sharedInstance.changed.addHandler(self) { (ssc) -> (Endpoint) -> () in
            ssc.libraryChanged
        }
    }
    
    func libraryChanged(_ e: Endpoint) {
        updateSelected(e)
        renderTable()
    }
}
