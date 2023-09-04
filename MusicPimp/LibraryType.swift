
import Foundation
import RxSwift

protocol LibraryType {
    var isLocal: Bool { get }
    var authValue: String { get }
    var authQuery: String { get }
    var contentsUpdated: Observable<MusicFolder?> { get }
    var rootFolderKey: String { get }
    
    func pingAuth() -> Single<Version>
    
    func rootFolder() -> Single<MusicFolder>
    func folder(_ id: FolderID) -> Single<MusicFolder>
    func tracks(_ id: FolderID) -> Single<[Track]>
    func search(_ term: String) -> Single<[Track]>
    
    func playlists() -> Single<[SavedPlaylist]>
    func playlist(_ id: PlaylistID) -> Single<SavedPlaylist>
    func popular(_ from: Int, until: Int) -> Single<[PopularEntry]>
    func recent(_ from: Int, until: Int) -> Single<[RecentEntry]>
    func savePlaylist(_ sp: SavedPlaylist) -> Single<PlaylistID>
    func deletePlaylist(_ id: PlaylistID) -> Single<HttpResponse>
    
    func alarms() -> Single<[Alarm]>
    func saveAlarm(_ alarm: Alarm) -> Single<HttpResponse>
    func deleteAlarm(_ id: AlarmID) -> Single<HttpResponse>
    func stopAlarm() -> Single<HttpResponse>
    func registerNotifications(_ token: PushToken, tag: String) -> Single<HttpResponse>
    func unregisterNotifications(_ tag: String) -> Single<HttpResponse>
}
