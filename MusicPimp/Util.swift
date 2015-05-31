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
    class func urlDecode(s: String) -> String {
        let unplussed = s.stringByReplacingOccurrencesOfString("+", withString: " ")
        return unplussed.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding) ?? unplussed
    }
    class func urlEncode(s: String) -> String {
        let plussed = s.stringByReplacingOccurrencesOfString(" ", withString: "+")
        return plussed.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) ?? plussed
    }
    class func test() {
        let ws = SRWebSocket()
    }
}
