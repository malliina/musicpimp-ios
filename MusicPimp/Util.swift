//
//  Util.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Util {
    private static var GlobalMainQueue: dispatch_queue_t {
        return dispatch_get_main_queue()
    }
    
    private static var GlobalUserInteractiveQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
    }
    
    private static var GlobalUserInitiatedQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
    }
    
    private static var GlobalUtilityQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.rawValue), 0)
    }
    private static var GlobalBackgroundQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
    }
    class func onUiThread(f: () -> Void) {
        dispatch_async(GlobalMainQueue, f)
    }
    class func onBackgroundThread(f: () -> Void) {
        dispatch_async(GlobalBackgroundQueue, f)
    }
    class func urlDecode(s: String) -> String {
        let unplussed = s.stringByReplacingOccurrencesOfString("+", withString: " ")
        return unplussed.stringByRemovingPercentEncoding ?? unplussed
    }
    class func urlEncode(s: String) -> String {
        let plussed = s.stringByReplacingOccurrencesOfString(" ", withString: "+")
//        plussed.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters: NSCharacterSet.URLPathAllowedCharacterSet())
        return plussed.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) ?? plussed
    }
    static func url(s: String) -> NSURL {
        return NSURL(string: s)!
    }
}