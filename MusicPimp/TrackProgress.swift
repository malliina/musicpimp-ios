
import Foundation

class TrackProgress {
    let track: Track
    let dpu: DownloadProgressUpdate
    
    var progress: Float { return Float(Double(dpu.written.toBytes) / Double(track.size.toBytes)) }
    
    var isCompleted: Bool { get { return track.size == dpu.written } }
    
    init(track: Track, dpu: DownloadProgressUpdate) {
        self.track = track
        self.dpu = dpu
    }
    
    static func initial(track: Track, info: DownloadTask) -> TrackProgress {
        return TrackProgress(track: track, dpu: DownloadProgressUpdate.initial(info: info, size: track.size))
    }
}
