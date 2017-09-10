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
    var subscription: Disposable? = nil
    
    let manager = LibraryManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscription = LibraryManager.sharedInstance.changed.addHandler(self) { (ssc) -> (Endpoint) -> () in
            ssc.libraryChanged
        }
    }
    
    func libraryChanged(_ e: Endpoint) {
        updateSelected(e)
        renderTable()
    }
    
    override func use(endpoint: Endpoint) {
        let _ = manager.use(endpoint: endpoint)
    }
    
    override func loadActive() -> Endpoint {
        return manager.loadActive()
    }
}
