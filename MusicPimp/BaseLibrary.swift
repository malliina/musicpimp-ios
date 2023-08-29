import Foundation
import RxSwift

open class BaseLibrary: LibraryType {
    var isLocal: Bool { get { return false } }
    var rootFolderKey: String { get { return "" } }
    var authValue: String { return "" }
    var authQuery: String { return "" }
    let contentsSubject = PublishSubject<MusicFolder?>()
    var contentsUpdated: Observable<MusicFolder?> { return contentsSubject }
    
    let notImplementedError = PimpError.simpleError(ErrorMessage("Not implemented yet"))
    
    func pingAuth() -> Single<Version> {
        Single.error(notImplementedError)
    }
    
    func folder(_ id: FolderID) -> Single<MusicFolder> {
        Single.error(notImplementedError)
    }
    
    func rootFolder() -> Single<MusicFolder> {
        Single.error(notImplementedError)
    }
    
    func tracks(_ id: FolderID) -> Single<[Track]> {
        tracksInner(id,  others: [], acc: [])
    }
    
    // the saved playlists
    func playlists() -> Single<[SavedPlaylist]> {
        Single.just([])
    }
    
    func playlist(_ id: PlaylistID) -> Single<SavedPlaylist> {
        Single.error(notImplementedError)
    }
    
    func popular(_ from: Int, until: Int) -> Single<[PopularEntry]> {
        Single.error(notImplementedError)
    }
    
    func recent(_ from: Int, until: Int) -> Single<[RecentEntry]> {
        Single.error(notImplementedError)
    }
    
    func savePlaylist(_ sp: SavedPlaylist) -> Single<PlaylistID> {
        Single.error(notImplementedError)
    }
    
    func deletePlaylist(_ id: PlaylistID) -> Single<HttpResponse> {
        Single.error(notImplementedError)
    }
    
    func search(_ term: String) -> Single<[Track]> {
        return Single.just([])
    }
    
    func alarms() -> Single<[Alarm]> {
        return Single.just([])
    }
    
    func saveAlarm(_ alarm: Alarm) -> Single<HttpResponse> {
        Single.error(notImplementedError)
    }
    
    func deleteAlarm(_ id: AlarmID) -> Single<HttpResponse> {
        Single.error(notImplementedError)
    }
    
    func stopAlarm() -> Single<HttpResponse> {
        Single.error(notImplementedError)
    }
    
    func registerNotifications(_ token: PushToken, tag: String) -> Single<HttpResponse> {
        Single.error(notImplementedError)
    }
    
    func unregisterNotifications(_ tag: String) -> Single<HttpResponse> {
        Single.error(notImplementedError)
    }
    
    func tracksInner(_ id: FolderID, others: [FolderID], acc: [Track]) -> Single<[Track]> {
        folder(id).flatMap { (result) -> Single<[Track]> in
            let subIDs = result.folders.map { $0.id }
            let remaining = others + subIDs
            let newAcc = acc + result.tracks
            if let head = remaining.first {
                let tail = remaining.tail()
                return self.tracksInner(head, others: tail, acc: newAcc)
            } else {
                return Single.just(newAcc)
            }
        }
    }
}
