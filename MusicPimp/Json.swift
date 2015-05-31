//
//  Json.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
class Json {
    static func asJson(input: String, error: NSErrorPointer) -> AnyObject? {
        if let data = input.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return asJson(data, error: error)
        }
        return nil
    }
    static func asJson(data: NSData, error: NSErrorPointer) -> AnyObject? {
        return NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: error)
    }

}
