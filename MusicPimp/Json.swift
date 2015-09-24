//
//  Json.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

public class Json {
    public static func asJson(input: String) throws -> AnyObject {
        let error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        if let data = input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return try asJson(data)
        }
        throw error
    }
    public static func asJson(data: NSData) throws -> AnyObject {
        return try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
    }
    public static func stringifyObject(value: [String: AnyObject], prettyPrinted: Bool = true) -> String? {
        return stringify(value, prettyPrinted: prettyPrinted)
    }
    public static func stringify(value: AnyObject, prettyPrinted: Bool = true) -> String? {
//        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        let options = NSJSONWritingOptions.PrettyPrinted
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = try? NSJSONSerialization.dataWithJSONObject(value, options: options) {
                return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
            }
        }
        return nil
    }
}
