//
//  Volume.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 27/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
protocol Volume {
    var value: UInt { get }
}
func volume(_ value: UInt) -> Volume? {
    class Vol: Volume {
        let value: UInt
        init(value: UInt) {
            self.value = value
        }
    }
    if value >= 0 && value <= 100 {
        return Vol(value: value)
    }
    return nil
}
