//
//  Util.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Util {
    class func onUiThread(f: () -> Any) {
        dispatch_async(dispatch_get_main_queue(), {
            () -> Void in
            f()
            ()
        })
    }
}