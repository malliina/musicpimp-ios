//
//  LibraryManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class LibraryManager: EndpointManager {
    let log = LoggerFactory.shared.pimp(LibraryManager.self)
    static let sharedInstance = LibraryManager()
    
    fileprivate var activeLibrary: LibraryType
    var active: LibraryType { get { return activeLibrary } }
    let libraryChanged = Event<LibraryType>()
 
    init() {
        let settings = PimpSettings.sharedInstance
        activeLibrary = Libraries.fromEndpoint(settings.activeEndpoint(PimpSettings.LIBRARY))
        super.init(key: PimpSettings.LIBRARY, settings: settings)
    }
    
    func endpoints() -> [Endpoint] {
        return settings.endpoints()
    }
    
    func use(endpoint: Endpoint) -> LibraryType {
        let _ = saveActive(endpoint)
        let client = Libraries.fromEndpoint(endpoint)
        activeLibrary = client
        log.info("Library set to \(endpoint.name)")
        libraryChanged.raise(client)
        return client
    }
}
