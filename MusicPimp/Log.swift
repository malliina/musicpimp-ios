//
//  Log.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class Log {
    static func info<T>(msg: T) -> Void {
        print(msg)
    }
    static func error<T>(msg: T) -> Void {
        print(msg)
    }
}
