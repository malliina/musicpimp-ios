
import Foundation
import AVFoundation

class PlayerInfo {
    let player: AVPlayer
    let track: Track
    
    init(player: AVPlayer, track: Track) {
        self.player = player
        self.track = track
    }
}
