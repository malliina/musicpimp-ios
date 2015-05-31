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
    
    private var activeLibrary: LibraryType
    var active: LibraryType { get { return activeLibrary } }
    let libraryChanged = Event<LibraryType>()
    
    init() {
        var settings = PimpSettings.sharedInstance
        activeLibrary = Libraries.fromEndpoint(settings.activeEndpoint(PimpSettings.LIBRARY))
        super.init(key: PimpSettings.LIBRARY, settings: settings)
        changed.addHandler(self, handler: { (lm) -> Endpoint -> () in
            lm.onNewLibraryEndpoint
        })
    }
    
    private func onNewLibraryEndpoint(endpoint: Endpoint) {
        let client = Libraries.fromEndpoint(endpoint)
        activeLibrary = client
        libraryChanged.raise(client)
    }
}
