//
//  Json.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class Json {
    open static func asJson(_ input: String) -> AnyObject? {
        if let data = input.data(using: String.Encoding.utf8, allowLossyConversion: false), let json = asJson(data) {
            return json
        }
        return nil
    }
    
    open static func asJson(_ data: Data) -> AnyObject? {
        return try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as AnyObject?
    }
    
    open static func stringifyObject(_ value: [String: AnyObject], prettyPrinted: Bool = true) -> String? {
        return stringify(value as AnyObject, prettyPrinted: prettyPrinted)
    }
    
    open static func stringify(_ value: AnyObject, prettyPrinted: Bool = true) -> String? {
//        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        let options = JSONSerialization.WritingOptions.prettyPrinted
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value, options: options) {
                return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
            }
        }
        return nil
    }
}
