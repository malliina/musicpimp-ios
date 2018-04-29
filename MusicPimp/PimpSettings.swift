//
//  JsonIO.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

open class PimpSettings {
    let log = LoggerFactory.shared.system(PimpSettings.self)
    static let ENDPOINTS = "endpoints", PLAYER = "player", LIBRARY = "library", CACHE_ENABLED = "cache_enabled", CACHE_LIMIT = "cache_limit", TASKS = "tasks", NotificationsPrefix = "notifications-", defaultAlarmEndpoint = "defaultAlarmEndpoint", NotificationsAllowed = "notificationsAllowed", PushTokenKey = "pushToken", NoPushTokenValue = "none", TrackHistory = "trackHistory", IsPremium = "isPremium"
    
    open static let sharedInstance = PimpSettings(impl: UserPrefs.sharedInstance)
    
    
    let endpointsSubject = PublishSubject<[Endpoint]>()
    var endpointsEvent: Observable<[Endpoint]> { return endpointsSubject }
    
    let cacheLimitSubject = PublishSubject<StorageSize>()
    var cacheLimitChanged: Observable<StorageSize> { return cacheLimitSubject }
    
    let cacheEnabledSubject = PublishSubject<Bool>()
    var cacheEnabledChanged: Observable<Bool> { return cacheEnabledSubject }
    
    let defaultAlarmEndpointSubject = PublishSubject<Endpoint>()
    var defaultAlarmEndpointChanged: Observable<Endpoint> { return defaultAlarmEndpointSubject }
    
    let notificationPermissionSubject = PublishSubject<Bool>()
    var notificationPermissionChanged: Observable<Bool> { return notificationPermissionSubject }
    
    let impl: Persistence
    
    init(impl: Persistence) {
        self.impl = impl
    }
    
    var trackHistory: [Date] {
        get {
            if let historyArray = impl.load(PimpSettings.TrackHistory) {
                return readHistory(historyArray)
            }
            return []
        }
        
        set(newHistory) {
            if let json = serializeHistory(newHistory) ?? serializeHistory([]) {
                let _ = impl.save(json, key: PimpSettings.TrackHistory)
            }
        }
    }
    
    open func readHistory(_ raw: String) -> [Date] {
        if let json = Json.asJson(raw) as? NSDictionary,
            let history = json[PimpSettings.TrackHistory] as? [Double] {
                return history.map { Date(timeIntervalSince1970: $0) }
        }
        return []
    }
    
    open func serializeHistory(_ history: [Date]) -> String? {
        let blob = [ PimpSettings.TrackHistory: history.map { $0.timeIntervalSince1970 } ]
        return Json.stringifyObject(blob as [String : AnyObject])
    }
    
    var changes: Observable<Setting> { get { return impl.changes } }
    
    var pushToken: PushToken? {
        get {
            let tokenString = impl.load(PimpSettings.PushTokenKey)
            if let tokenString = tokenString {
                if tokenString != PimpSettings.NoPushTokenValue {
                    return PushToken(token: tokenString)
                }
            }
            return nil
        }
        set(newToken) {
            let token = newToken?.token ?? PimpSettings.NoPushTokenValue
            let _ = impl.save(token, key: PimpSettings.PushTokenKey)
        }
    }
    
    var notificationsAllowed: Bool {
        get { return impl.load(PimpSettings.NotificationsAllowed) == "true" }
        set(allowed) {
            let errors = impl.save("\(allowed)", key: PimpSettings.NotificationsAllowed)
            if errors == nil {
                notificationPermissionSubject.onNext(allowed)
            }
        }
    }
    
    var cacheEnabled: Bool {
        get { return impl.load(PimpSettings.CACHE_ENABLED) != "false" }
        set(value) {
            let errors = impl.save("\(value)", key: PimpSettings.CACHE_ENABLED)
            if errors == nil {
                cacheEnabledSubject.onNext(value)
            }
        }
    }
    
    var isUserPremium: Bool {
        get { return impl.load(PimpSettings.IsPremium) == "true" }
        set(value) {
            let _ = impl.save("\(value)", key: PimpSettings.IsPremium)
        }
    }
    
    let defaultLimit = StorageSize(gigs: 10)
    
    var cacheLimit: StorageSize {
        get {
            if let bytesAsString = impl.load(PimpSettings.CACHE_LIMIT) {
                if let asLong = NumberFormatter().number(from: bytesAsString)?.int64Value {
                    return StorageSize.fromBytes(asLong) ?? defaultLimit
                }
            }
            return defaultLimit
        }
        set(newLimit) {
            let errors = impl.save("\(newLimit.toBytes)", key: PimpSettings.CACHE_LIMIT)
            if errors == nil {
                cacheLimitSubject.onNext(newLimit)
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
    
    func initDefaultNotificationEndpoint(_ es: [Endpoint]) -> Endpoint? {
        let result = es.headOption()
        if let result = result {
            saveDefaultNotificationsEndpoint(result)
        }
        return result
    }
    
    func saveDefaultNotificationsEndpoint(_ e: Endpoint) {
        let errors = impl.save(e.id, key: PimpSettings.defaultAlarmEndpoint)
        if errors == nil {
            defaultAlarmEndpointSubject.onNext(e)
        }
    }
    
    func notificationsEnabled(_ e: Endpoint) -> Bool {
        return impl.load(notificationsKey(e)) == "true"
    }
    
    func saveNotificationsEnabled(_ e: Endpoint, enabled: Bool) -> ErrorMessage? {
        return impl.save("\(enabled)", key: notificationsKey(e))
    }
    
    fileprivate func notificationsKey(_ e: Endpoint) -> String {
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
    
    func activePlayer() -> Endpoint {
        return activeEndpoint(PimpSettings.PLAYER)
    }
    
    func activeLibrary() -> Endpoint {
        return activeEndpoint(PimpSettings.LIBRARY)
    }
    
    func activeEndpoint(_ key: String) -> Endpoint {
        if let id = impl.load(key) {
            return endpoints().find({ $0.id == id }) ?? Endpoint.Local
        }
        return Endpoint.Local
    }
    
    func save(_ endpoint: Endpoint) {
        var es = endpoints()
        if let idx = es.index(where: { $0.id == endpoint.id }) {
            es.remove(at: idx)
            es.insert(endpoint, at: idx)
        } else {
            es.append(endpoint)
        }
        saveAll(es)
    }
    
    func saveAll(_ es: [Endpoint]) {
        if let stringified = serialize(es) {
            let _ = impl.save(stringified, key: PimpSettings.ENDPOINTS)
            let esAfter = endpoints()
            endpointsSubject.onNext(esAfter)
        } else {
            log.error("Unable to save endpoints")
        }
    }
    
    func serialize(_ es: [Endpoint]) -> String? {
        let jsonified = es.map(PimpJson.sharedInstance.toJson)
        let blob = [PimpSettings.ENDPOINTS: jsonified as AnyObject]
        return Json.stringifyObject(blob, prettyPrinted: true)
    }
    
    func tasks(_ sid: String) -> [Int: DownloadInfo] {
        let key = taskKey(sid)
        if let str = impl.load(key),
            let json = Json.asJson(str) as? NSDictionary,
            let dict = json as? [String: AnyObject],
            let tasks = PimpJson.sharedInstance.asTasks(dict) {
            return tasks
        }
        return [:]
    }
    
    func saveTasks(_ sid: String, tasks: [Int: DownloadInfo]) -> ErrorMessage? {
        if let stringified = serialize(tasks) {
            return impl.save(stringified, key: taskKey(sid))
        } else {
            let msg = "Unable to serialize tasks"
            log.error(msg)
            return ErrorMessage(message: msg)
        }
    }
    
    func taskKey(_ sid: String) -> String {
        return "\(PimpSettings.TASKS)-\(sid)"
    }
    
    func serialize(_ tasks: [Int: DownloadInfo]) -> String? {
        let jsonified = PimpJson.sharedInstance.toJson(tasks)
        return Json.stringifyObject(jsonified, prettyPrinted: true)
    }
}
