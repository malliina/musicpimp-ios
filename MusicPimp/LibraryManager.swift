//
//  LibraryManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryManager: EndpointManager {
    static let sharedInstance = LibraryManager()
    
    fileprivate var activeLibrary: LibraryType
    var active: LibraryType { get { return activeLibrary } }
    let libraryChanged = Event<LibraryType>()
    var subscription: Disposable? = nil
    
    init() {
        let settings = PimpSettings.sharedInstance
        activeLibrary = Libraries.fromEndpoint(settings.activeEndpoint(PimpSettings.LIBRARY))
        super.init(key: PimpSettings.LIBRARY, settings: settings)
        subscription = changed.addHandler(self, handler: { (lm) -> (Endpoint) -> () in
            lm.onNewLibraryEndpoint
        })
    }
    
    fileprivate func onNewLibraryEndpoint(_ endpoint: Endpoint) {
        let client = Libraries.fromEndpoint(endpoint)
        activeLibrary = client
        libraryChanged.raise(client)
    }
}
