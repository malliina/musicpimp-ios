//
//  JsonIO.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpSettings {
    static let ENDPOINTS = "endpoints", PLAYER = "player", LIBRARY = "library", CACHE_ENABLED = "cache_enabled", CACHE_LIMIT = "cache_limit", TASKS = "tasks", NotificationsPrefix = "notifications-", defaultAlarmEndpoint = "defaultAlarmEndpoint", NotificationsAllowed = "notificationsAllowed"
    
    static let sharedInstance = PimpSettings(impl: UserPrefs.sharedInstance)
    
    let endpointsEvent = Event<[Endpoint]>()
    let playerChanged = Event<Endpoint>()
    let libraryChanged = Event<Endpoint>()
    let cacheLimitChanged = Event<StorageSize>()
    let cacheEnabledChanged = Event<Bool>()
    let defaultAlarmEndpointChanged = Event<Endpoint>()
    
    let impl: Persistence
    
    init(impl: Persistence) {
        self.impl = impl
    }
    
    var changes: Event<Setting> { get { return impl.changes } }
    
    var notificationsAllowed: Bool {
        get { return impl.load(PimpSettings.NotificationsAllowed) == "true" }
        set(allowed) { impl.save("\(allowed)", key: PimpSettings.NotificationsAllowed) }
    }
    
    var cacheEnabled: Bool {
        get { return impl.load(PimpSettings.CACHE_ENABLED) != "false" }
        set(value) {
            let errors = impl.save("\(value)", key: PimpSettings.CACHE_ENABLED)
            if errors == nil {
                cacheEnabledChanged.raise(value)
            }
        }
    }
    let defaultLimit = StorageSize(gigs: 10)
    
    var cacheLimit: StorageSize {
        get {
            if let bytesAsString = impl.load(PimpSettings.CACHE_LIMIT) {
                if let asLong = NSNumberFormatter().numberFromString(bytesAsString)?.longLongValue {
                    return StorageSize.fromBytes(asLong) ?? defaultLimit
                }
            }
            return defaultLimit
        }
        set(newLimit) {
            let errors = impl.save("\(newLimit.toBytes)", key: PimpSettings.CACHE_LIMIT)
            if errors == nil {
                cacheLimitChanged.raise(newLimit)
            }
        }
    }
    
    func defaultNotificationEndpoint() -> Endpoint? {
        let alarmEndpoints = endpoints().filter { $0.supportsAlarms }
        if let id = impl.load(PimpSettings.defaultAlarmEndpoint) {
            let e = alarmEndpoints.find { $0.id == id }
            return e ?? initDefaultNotificationEndpoint(alarmEndpoints)
        } else {
            return initDefaultNotificationEndpoint(alarmEndpoints)
        }
    }
    
    func initDefaultNotificationEndpoint(es: [Endpoint]) -> Endpoint? {
        let result = es.headOption()
        if let result = result {
            saveDefaultNotificationsEndpoint(result)
        }
        return result
    }
    
    func saveDefaultNotificationsEndpoint(e: Endpoint) {
        let errors = impl.save(e.id, key: PimpSettings.defaultAlarmEndpoint)
        if errors == nil {
            defaultAlarmEndpointChanged.raise(e)
        }
    }
    
    func notificationsEnabled(e: Endpoint) -> Bool {
        return impl.load(notificationsKey(e)) == "true"
    }
    
    func saveNotificationsEnabled(e: Endpoint, enabled: Bool) {
        impl.save("\(enabled)", key: notificationsKey(e))
    }
    
    private func notificationsKey(e: Endpoint) -> String {
        return PimpSettings.NotificationsPrefix + e.id
    }
    
    func endpoints() -> [Endpoint] {
        if let str = impl.load(PimpSettings.ENDPOINTS) {
            if let json: AnyObject = Json.asJson(str) {
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
        return Json.stringifyObject(blob, prettyPrinted: true)
    }
    
    func tasks(sid: String) -> [Int: DownloadInfo] {
        let key = taskKey(sid)
        if let str = impl.load(key),
            json = Json.asJson(str) as? NSDictionary,
            tasks = PimpJson.sharedInstance.asTasks(json) {
            return tasks
        }
        return [:]
    }
    
    func saveTasks(sid: String, tasks: [Int: DownloadInfo]) {
        if let stringified = serialize(tasks) {
            impl.save(stringified, key: taskKey(sid))
        } else {
            Log.error("Unable to save tasks")
        }
    }
    
    func taskKey(sid: String) -> String {
        return "\(PimpSettings.TASKS)-\(sid)"
    }
    
    func serialize(tasks: [Int: DownloadInfo]) -> String? {
        let jsonified = PimpJson.sharedInstance.toJson(tasks)
        return Json.stringifyObject(jsonified, prettyPrinted: true)
    }
}
