//
//  TrackProgress.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 25/12/15.
//  Copyright © 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class TrackProgress {
    let track: Track
    let dpu: DownloadProgressUpdate
    
    var progress: Float { return Float(Double(dpu.written.toBytes) / Double(track.size.toBytes)) }
    
    init(track: Track, dpu: DownloadProgressUpdate) {
        self.track = track
        self.dpu = dpu
    }
}
