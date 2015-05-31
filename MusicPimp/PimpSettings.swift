//
//  JsonIO.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpSettings {
    static let ENDPOINTS = "endpoints", PLAYER = "player", LIBRARY = "library"
    
    static let sharedInstance = PimpSettings(impl: UserPrefs.sharedInstance)
    
    let endpointsEvent = Event<[Endpoint]>()
    let playerChanged = Event<Endpoint>()
    let libraryChanged = Event<Endpoint>()
    
    let impl: Persistence
    init(impl: Persistence) {
        self.impl = impl
    }
    
    func endpoints() -> [Endpoint] {
        if let str = impl.load(PimpSettings.ENDPOINTS) {
            var error: NSError?
            if let json: AnyObject = Json.asJson(str, error: &error) {
                if let dict = json as? NSDictionary {
                    if let endArray = dict[PimpSettings.ENDPOINTS] as? [NSDictionary] {
                        // TODO Fix
                        return endArray.flatMapOpt(PimpJson.sharedInstance.asEndpoint)
                    }
                }
            }
        }
        return []
    }
    func activeEndpoint(key: String) -> Endpoint {
        if let id = impl.load(key) {
            return endpoints().find({ $0.id == id }) ?? Endpoint.Local
        }
        return Endpoint.Local
    }
    func save(endpoint: Endpoint) {
        var es = endpoints()
        if let idx = es.indexOf({ $0.id == endpoint.id }) {
            es.removeAtIndex(idx)
            es.insert(endpoint, atIndex: idx)
        } else {
            es.append(endpoint)
        }
        saveAll(es)
    }
    func saveAll(es: [Endpoint]) {
        if let stringified = serialize(es) {
            impl.save(stringified, key: PimpSettings.ENDPOINTS)
            let esAfter = endpoints()
            Log.info("Endpoints now: \(esAfter.count)")
            endpointsEvent.raise(esAfter)
        } else {
            Log.error("Unable to save endpoints")
        }
        
    }
    func serialize(es: [Endpoint]) -> String? {
        let jsonified = es.map(PimpJson.sharedInstance.toJson)
        let blob = [PimpSettings.ENDPOINTS: jsonified]
        return PimpJson.sharedInstance.stringify(blob, prettyPrinted: true)
    }
}
