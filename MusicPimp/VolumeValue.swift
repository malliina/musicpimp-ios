//
//  VolumeValue.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 10/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class VolumeValue {
    static let Min = VolumeValue(volume: 0)
    static let Max = VolumeValue(volume: 100)
    static let Default = VolumeValue(volume: 40)
    
    let volume: Int
    
    init(volume: Int) {
        self.volume = volume
    }
    
    init(volumeFloat: Float) {
        self.volume = Int(volumeFloat * 100)
    }
    
    func toFloat() -> Float {
        return Float(1.0 * Float(volume) / 100.0)
    }
}
