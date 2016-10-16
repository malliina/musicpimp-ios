//
//  Util.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/03/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Util {
    fileprivate static var GlobalMainQueue: DispatchQueue {
        return DispatchQueue.main
    }
    
    
    class func onUiThread(_ f: @escaping () -> Void) {
        DispatchQueue.main.async(execute: f)
    }
    
    class func onBackgroundThread(_ f: @escaping () -> Void) {
        //DispatchQueue.global(attributes: .background).async(execute: f)
        DispatchQueue.main.async(execute: f)
    }
    
    class func urlDecodeWithPlus(_ s: String) -> String {
        let unplussed = s.replacingOccurrences(of: "+", with: " ")
        return unplussed.removingPercentEncoding ?? unplussed
    }
    
    class func urlEncodePathWithPlus(_ s: String) -> String {
        let plussed = s.replacingOccurrences(of: " ", with: "+")
        return urlEncodePath(plussed)
    }
    
    class func urlEncodeHost(_ s: String) -> String {
        return encodeWith(s, cs: .urlHostAllowed)
    }
    
    class func urlEncodePath(_ s: String) -> String {
        return encodeWith(s, cs: .urlPathAllowed)
    }
    
    class func urlEncodeQueryString(_ s: String) -> String {
        return encodeWith(s, cs: .urlQueryAllowed)
    }
    
    fileprivate class func encodeWith(_ s: String, cs: CharacterSet) -> String {
        return s.addingPercentEncoding(withAllowedCharacters: cs) ?? s
    }
        
    static func onError(_ pimpError: PimpError) {
        let message = PimpErrorUtil.stringifyDetailed(pimpError)
        Log.error(message)
    }
}

extension Data {
    // thanks Martin, http://codereview.stackexchange.com/a/86613
    func hexString() -> String {
        // "Array" of all bytes
        let bytes = UnsafeBufferPointer<UInt8>(start: (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count), count: self.count)
        // Array of hex strings, one for each byte
        let hexBytes = bytes.map { String(format: "%02hhx", $0) }
        // Concatenates all hex strings
        return hexBytes.joined(separator: "")
    }
}

