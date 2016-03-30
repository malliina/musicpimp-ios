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
    
    class func urlDecodeWithPlus(s: String) -> String {
        let unplussed = s.stringByReplacingOccurrencesOfString("+", withString: " ")
        return unplussed.stringByRemovingPercentEncoding ?? unplussed
    }
    
    class func urlEncodePathWithPlus(s: String) -> String {
        let plussed = s.stringByReplacingOccurrencesOfString(" ", withString: "+")
        return urlEncodePath(plussed)
    }
    
    class func urlEncodeHost(s: String) -> String {
        return encodeWith(s, cs: .URLHostAllowedCharacterSet())
    }
    
    class func urlEncodePath(s: String) -> String {
        return encodeWith(s, cs: .URLPathAllowedCharacterSet())
    }
    
    class func urlEncodeQueryString(s: String) -> String {
        return encodeWith(s, cs: .URLQueryAllowedCharacterSet())
    }
    
    private class func encodeWith(s: String, cs: NSCharacterSet) -> String {
        return s.stringByAddingPercentEncodingWithAllowedCharacters(cs) ?? s
    }
    
    static func url(s: String) -> NSURL {
        return NSURL(string: s)!
    }
}

extension NSData {
    // thanks Martin, http://codereview.stackexchange.com/a/86613
    func hexString() -> String {
        // "Array" of all bytes
        let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes), count: self.length)
        // Array of hex strings, one for each byte
        let hexBytes = bytes.map { String(format: "%02hhx", $0) }
        // Concatenates all hex strings
        return hexBytes.joinWithSeparator("")
    }
}

