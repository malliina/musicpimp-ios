//
//  JsonIO.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

struct TrackPlaybackHistory: Codable {
    let history: [Date]
}

open class PimpSettings {
    let log = LoggerFactory.shared.system(PimpSettings.self)
    static let ENDPOINTS = "endpoints", PLAYER = "v2-player", LIBRARY = "v2-library", CACHE_ENABLED = "v2-cache_enabled", CACHE_LIMIT = "v2-cache_limit", TASKS = "v2-tasks", NotificationsPrefix = "v2-notifications-", defaultAlarmEndpoint = "v2-defaultAlarmEndpoint", NotificationsAllowed = "v2-notificationsAllowed", PushTokenKey = "v2-pushToken", NoPushTokenValue = "v2-none", TrackHistory = "v2-trackHistory", IsPremium = "v2-isPremium"
    
    public static let sharedInstance = PimpSettings(impl: UserPrefs.sharedInstance)
    
    let endpointsSubject = PublishSubject<[Endpoint]>()
    var endpointsEvent: Observable<[Endpoint]> { endpointsSubject }
    
    let cacheLimitSubject = PublishSubject<StorageSize>()
    var cacheLimitChanged: Observable<StorageSize> { cacheLimitSubject }
    
    let cacheEnabledSubject = PublishSubject<Bool>()
    var cacheEnabledChanged: Observable<Bool> { cacheEnabledSubject }
    
    let defaultAlarmEndpointSubject = PublishSubject<Endpoint>()
    var defaultAlarmEndpointChanged: Observable<Endpoint> { defaultAlarmEndpointSubject }
    
    let notificationPermissionSubject = PublishSubject<Bool>()
    var notificationPermissionChanged: Observable<Bool> { notificationPermissionSubject }
    
    let impl: Persistence
    
    init(impl: Persistence) {
        self.impl = impl
    }
    
    var trackHistory: [Date] {
        get {
            (impl.load(PimpSettings.TrackHistory, TrackPlaybackHistory.self) ?? TrackPlaybackHistory(history: [])).history
        }
        
        set (newHistory) {
            let _ = impl.save(TrackPlaybackHistory(history: newHistory), key: PimpSettings.TrackHistory)
        }
    }
    
    var changes: Observable<Setting> { get { return impl.changes } }
    
    var pushToken: PushToken? {
        get {
            let token = impl.load(PimpSettings.PushTokenKey, Wrapped<PushToken>.self)?.value
            if let token = token {
                if token != PushToken.noToken {
                    return token
                }
            }
            return nil
        }
        set (newToken) {
            let token = newToken ?? PushToken.noToken
            let _ = impl.saveString(token.token, key: PimpSettings.PushTokenKey)
        }
    }
    
    var notificationsAllowed: Bool {
        get { impl.loadBool(PimpSettings.NotificationsAllowed) ?? false }
        set (allowed) {
            let errors = impl.saveBool(allowed, key: PimpSettings.NotificationsAllowed)
            if errors == nil {
                notificationPermissionSubject.onNext(allowed)
            }
        }
    }
    
    var cacheEnabled: Bool {
        get { impl.loadBool(PimpSettings.CACHE_ENABLED) ?? true }
        set (value) {
            let errors = impl.saveBool(value, key: PimpSettings.CACHE_ENABLED)
            if errors == nil {
                cacheEnabledSubject.onNext(value)
            }
        }
    }
    
    var isUserPremium: Bool {
        get { return impl.loadBool(PimpSettings.IsPremium) ?? false }
        set (value) {
            let _ = impl.saveBool(value, key: PimpSettings.IsPremium)
        }
    }
    
    let defaultLimit = StorageSize(gigs: 10)
    
    var cacheLimit: StorageSize {
        get {
            impl.load(PimpSettings.CACHE_LIMIT, Wrapped<StorageSize>.self)?.value ?? defaultLimit
        }
        set (newLimit) {
            if let error = impl.save(Wrapped(newLimit), key: PimpSettings.CACHE_LIMIT) {
                log.error("Failed to save cache limit: \(error.message)")
            } else {
                log.info("Saved cache limit to \(newLimit)")
                cacheLimitSubject.onNext(newLimit)
            }
        }
    }
    
    func defaultNotificationEndpoint() -> Endpoint? {
        let alarmEndpoints = endpoints().filter { $0.supportsAlarms }
        if let id = impl.loadString(PimpSettings.defaultAlarmEndpoint),
           let e = alarmEndpoints.find({ $0.id == id }) {
            return e
        } else {
            return initDefaultNotificationEndpoint(alarmEndpoints)
        }
    }
    
    func initDefaultNotificationEndpoint(_ es: [Endpoint]) -> Endpoint? {
        let result = es.headOption()
        if let result = result {
            saveDefaultNotificationsEndpoint(result, publish: false)
        }
        return result
    }
    
    func saveDefaultNotificationsEndpoint(_ e: Endpoint, publish: Bool) {
        let errors = impl.save(e.id, key: PimpSettings.defaultAlarmEndpoint)
        if errors == nil && publish {
            defaultAlarmEndpointSubject.onNext(e)
        }
    }
    
    func notificationsEnabled(_ e: Endpoint) -> Bool {
        impl.loadBool(notificationsKey(e)) ?? false
    }
    
    func saveNotificationsEnabled(_ e: Endpoint, enabled: Bool) -> ErrorMessage? {
        impl.saveBool(enabled, key: notificationsKey(e))
    }
    
    fileprivate func notificationsKey(_ e: Endpoint) -> String {
        PimpSettings.NotificationsPrefix + e.id
    }
    
    func endpoints() -> [Endpoint] {
        impl.load(PimpSettings.ENDPOINTS, EndpointsContainer.self)?.endpoints ?? []
    }
    
    func activePlayer() -> Endpoint {
        activeEndpoint(PimpSettings.PLAYER)
    }
    
    func activeLibrary() -> Endpoint {
        activeEndpoint(PimpSettings.LIBRARY)
    }
    
    func activeEndpoint(_ key: String) -> Endpoint {
        if let id = impl.loadString(key) {
            return endpoints().find({ $0.id == id }) ?? Endpoint.Local
        }
        return Endpoint.Local
    }
    
    func save(_ endpoint: Endpoint) {
        var es = endpoints()
        if let idx = es.firstIndex(where: { $0.id == endpoint.id }) {
            es.remove(at: idx)
            es.insert(endpoint, at: idx)
        } else {
            es.append(endpoint)
        }
        saveAll(es)
    }
    
    func saveAll(_ es: [Endpoint]) {
        if impl.save(EndpointsContainer(endpoints: es), key: PimpSettings.ENDPOINTS) == nil {
            let esAfter = endpoints()
            endpointsSubject.onNext(esAfter)
        } else {
            log.error("Unable to save endpoints")
        }
    }
    
    func tasks(_ sid: String) -> DownloadTasks {
        let key = taskKey(sid)
        return impl.load(key, DownloadTasks.self) ?? DownloadTasks(tasks: [])
    }
    
    func saveTasks(_ sid: String, tasks: [DownloadTask]) -> ErrorMessage? {
        impl.save(DownloadTasks(tasks: tasks), key: taskKey(sid))
    }
    
    func taskKey(_ sid: String) -> String {
        "\(PimpSettings.TASKS)-\(sid)"
    }
}
