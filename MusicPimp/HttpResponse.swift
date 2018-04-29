//
//  HttpResponse.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/04/2018.
//  Copyright © 2018 Skogberg Labs. All rights reserved.
//

import Foundation

class HttpResponse {
    let http: HTTPURLResponse
    let data: Data
    
    var statusCode: Int { return http.statusCode }
    var isStatusOK: Bool { return statusCode >= 200 && statusCode < 300 }
    var json: NSDictionary? { return jsonData as? NSDictionary }
    var jsonData: AnyObject? { return Json.asJson(data) }
    
//    var errors: [SingleError] {
//        get {
//            if let json = json, let errors = json["errors"] as? [NSDictionary] {
//                return errors.compactMap({ (dict) -> SingleError? in
//                    if let key = dict["key"] as? String, let message = dict["message"] as? String {
//                        return ErrorMessage(key: key, message: message)
//                    } else {
//                        return nil
//                    }
//                })
//            } else {
//                return []
//            }
//        }
//    }
    
    init(http: HTTPURLResponse, data: Data) {
        self.http = http
        self.data = data
    }
}
