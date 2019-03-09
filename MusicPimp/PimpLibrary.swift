//
//  PimpLibrary.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

open class PimpLibrary: BaseLibrary {
    static let log = LoggerFactory.shared.pimp(PimpLibrary.self)
    let endpoint: Endpoint
    let client: PimpHttpClient
    override var authValue: String { return endpoint.authHeader }
    override var authQuery: String { return endpoint.authQueryString }
    
    init(endpoint: Endpoint, client: PimpHttpClient) {
        self.endpoint = endpoint
        self.client = client
    }

    override func pingAuth() -> Single<Version> {
        return client.pingAuth()
    }
    
    override func rootFolder() -> Single<MusicFolder> {
        return client.pimpGetParsed(Endpoints.FOLDERS, to: MusicFolder.self)
    }
    
    override func folder(_ id: FolderID) -> Single<MusicFolder> {
        return client.pimpGetParsed("\(Endpoints.FOLDERS)/\(id)", to: MusicFolder.self)
    }
    
    override func tracks(_ id: FolderID) -> Single<[Track]> {
        return tracksInner(id,  others: [], acc: [])
    }
    
    override func playlists() -> Single<[SavedPlaylist]> {
        return client.pimpGetParsed("\(Endpoints.PLAYLISTS)", to: SavedPlaylists.self).map { $0.playlists }
    }
    
    override func playlist(_ id: PlaylistID) -> Single<SavedPlaylist> {
        return client.pimpGetParsed("\(Endpoints.PLAYLISTS)\(id.id)", to: SavedPlaylistResponse.self).map { $0.playlist }
    }
    
    override func popular(_ from: Int, until: Int) -> Single<[PopularEntry]> {
        return client.pimpGetParsed("\(Endpoints.Popular)?from=\(from)&until=\(until)", to: Populars.self).map { $0.populars }
    }
    
    override func recent(_ from: Int, until: Int) -> Single<[RecentEntry]> {
        return client.pimpGetParsed("\(Endpoints.Recent)?from=\(from)&until=\(until)", to: Recents.self).map { $0.recents }
    }
    
    override func savePlaylist(_ sp: SavedPlaylist) -> Single<PlaylistID> {
        return client.pimpPostParsed(Endpoints.PLAYLISTS, payload: SavePlaylistPayload(playlist: sp.strip()), to: PlaylistIdResponse.self).map { $0.id }
    }
    
    override func deletePlaylist(_ id: PlaylistID) -> Single<HttpResponse> {
        return client.pimpPostEmpty("\(Endpoints.PLAYLIST_DELETE)/\(id.id)")
    }
    
    override func search(_ term: String) -> Single<[Track]> {
        if let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            return client.pimpGetParsed("\(Endpoints.SEARCH)?term=\(encodedTerm)", to: [Track].self)
        } else {
            return Single.error(PimpError.simple("Invalid search term: \(term)"))
        }
    }
    
    override func alarms() -> Single<[Alarm]> {
        return client.pimpGetParsed(Endpoints.ALARMS, to: [AlarmJson<AlarmJob>].self).map { $0.map { $0.asAlarm() } }
    }
    
    override func saveAlarm(_ alarm: Alarm) -> Single<HttpResponse> {
        return client.pimpPost(Endpoints.ALARMS, payload: SaveAlarm(ap: alarm.asJson(), enabled: alarm.enabled))
    }
    
    override func deleteAlarm(_ id: AlarmID) -> Single<HttpResponse> {
        return alarmsPost(DeleteAlarm(id: id))
    }
    
    override func stopAlarm() -> Single<HttpResponse> {
        return alarmsPost(SimpleCommand(cmd: JsonKeys.STOP))
    }
    
    override func registerNotifications(_ token: PushToken, tag: String) -> Single<HttpResponse> {
        return alarmsPost(RegisterPush(id: token, tag: tag))
    }
    
    override func unregisterNotifications(_ tag: String) -> Single<HttpResponse> {
        return alarmsPost(UnregisterPush(id: tag))
    }
    
    fileprivate func alarmsPost<T: Encodable>(_ payload: T) -> Single<HttpResponse> {
        return client.pimpPost(Endpoints.ALARMS, payload: payload)
    }
}
