//
//  Json.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class Json {
    public static func asJson(input: String, error: NSErrorPointer) -> AnyObject? {
        if let data = input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return asJson(data, error: error)
        }
        return nil
    }
    public static func asJson(data: NSData, error: NSErrorPointer) -> AnyObject? {
        return NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: error)
    }
    public static func stringifyObject(value: [String: AnyObject], prettyPrinted: Bool = true) -> String? {
        return stringify(value, prettyPrinted: prettyPrinted)
    }
    public static func stringify(value: AnyObject, prettyPrinted: Bool = true) -> String? {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
            }
        }
        return nil
    }
}
