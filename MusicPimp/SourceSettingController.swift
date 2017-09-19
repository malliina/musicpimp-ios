//
//  SourceSettingController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class SourceSettingController: EndpointSelectController, LibraryEndpointDelegate {
    var subscription: Disposable? = nil
    
    let manager = LibraryManager.sharedInstance
    
    let listener = EndpointsListener()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listener.libraries = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener.subscribe()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listener.unsubscribe()
    }
    
    func onLibraryChanged(to newLibrary: Endpoint) {
        updateSelected(newLibrary)
        renderTable()
    }
    
    override func use(endpoint: Endpoint) {
        let _ = manager.use(endpoint: endpoint)
    }
    
    override func loadActive() -> Endpoint {
        return manager.loadActive()
    }
}
