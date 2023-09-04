
import Foundation

class ListeningController: PimpViewController, PlaybackEventDelegate, LibraryDelegate {
    var playerManager: PlayerManager { PlayerManager.sharedInstance }
    var player: PlayerType { playerManager.active }
    
    var libraryManager: LibraryManager { LibraryManager.sharedInstance }
    var library: LibraryType { libraryManager.active }
    
    let listener = PlaybackListener()
    let libraryListener = LibraryListener()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listener.playbacks = self
        libraryListener.delegate = self
        libraryListener.subscribe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listener.subscribe()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listener.unsubscribe()
    }
    
    func onTrackChanged(_ track: Track?) {
        if let track = track {
            updateMedia(track)
        } else {
            updateNoMedia()
        }
    }
    
    func updateMedia(_ track: Track) {
        
    }
    
    func updateNoMedia() {
        
    }
    
    func onTimeUpdated(_ position: Duration) {
        
    }
    
    func onStateChanged(_ state: PlaybackState) {
        
    }
    
    func onLibraryUpdated(to newLibrary: LibraryType) {
        
    }
}
