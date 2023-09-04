
import Foundation
import RxSwift

protocol PlaylistType {
    var indexSubject: PublishSubject<Int?> { get }
    var indexEvent: Observable<Int?> { get }
    var playlistSubject: PublishSubject<Playlist> { get }
    var playlistEvent: Observable<Playlist> { get }
    var trackSubject: PublishSubject<Track> { get }
    var trackAdded: Observable<Track> { get }
    
    func add(_ track: Track) -> ErrorMessage?
    
    func add(_ tracks: [Track]) -> [ErrorMessage]
    
    func removeIndex(_ index: Int) -> ErrorMessage?
    
    func move(_ src: Int, dest: Int) -> ErrorMessage?
    
    func reset(_ index: Int?, tracks: [Track]) -> ErrorMessage?
}
