//
//  EndpointManager.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 17/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class EndpointManager {
    let key: String
    let settings: PimpSettings
    let changed = Event<Endpoint>()
    
    init(key: String, settings: PimpSettings) {
        self.key = key
        self.settings = settings
    }
    
    func saveActive(e: Endpoint) {
        settings.impl.save(e.id, key: key)
        changed.raise(e)
    }
    
    func loadActive() -> Endpoint {
        if let id = settings.impl.load(key) {
            return settings.endpoints().find({ $0.id == id }) ?? Endpoint.Local
        }
        return Endpoint.Local
    }
}
