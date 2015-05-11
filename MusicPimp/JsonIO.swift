//
//  JsonIO.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class JsonIO {
    static let ENDPOINTS = "endpoints"
    
    static let sharedInstance = JsonIO(impl: UserPrefs.sharedInstance)
    
    let impl: Persistence
    init(impl: Persistence) {
        self.impl = impl
    }
    
    func endpoints() -> [Endpoint] {
        if let str = impl.load(JsonIO.ENDPOINTS) {
            var error: NSError?
            if let json: AnyObject = Json.asJson(str, error: &error) {
                if let dict = json as? NSDictionary {
                    if let endArray = dict[JsonIO.ENDPOINTS] as? [NSDictionary] {
                        // TODO Fix
                        return endArray.map(PimpJson.sharedInstance.asEndpoint).map({ $0! })
                    }
                }
            }
        }
        return []
    }
    func save(endpoint: Endpoint) {
        var es = endpoints()
        if let idx = es.indexOf({ $0.id == endpoint.id }) {
            es.removeAtIndex(idx)
            es.insert(endpoint, atIndex: idx)
        } else {
            es.append(endpoint)
        }
        if let stringified = serialize(es) {
            impl.save(stringified, key: JsonIO.ENDPOINTS)
        }
        let esAfter = endpoints()
        Log.info("Endpoints now: \(esAfter.count)")
    }
    func serialize(es: [Endpoint]) -> String? {
        let jsonified = es.map(PimpJson.sharedInstance.toJson)
        let blob = [JsonIO.ENDPOINTS: jsonified]
        return PimpJson.sharedInstance.stringify(blob, prettyPrinted: true)
    }
}
