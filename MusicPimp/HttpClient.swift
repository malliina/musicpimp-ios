//
// Created by Michael Skogberg on 15/02/15.
// Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class HttpClient {
    static let JSON = "application/json", CONTENT_TYPE = "Content-Type", ACCEPT = "Accept", GET = "GET", POST = "POST", AUTHORIZATION = "Authorization", BASIC = "Basic"

    static func basicAuthValue(username:String, password:String) -> String {
        let encodable = "\(username):\(password)"
        let encoded = encodable.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
        return "\(HttpClient.BASIC) \(encoded)"
    }
    
    func get(url: String, headers: [String: String] = [:], onResponse: (NSData, NSHTTPURLResponse) -> Void, onError: (NSData, NSError) -> Void) {
        get(url, headers: headers, completionHandler: handlify(onResponse, onError: onError))
    }

    func get(url: String, headers: [String: String] = [:], completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
        get(NSURL(string: url)!, headers: headers, completionHandler: completionHandler)
    }

    func get(url: NSURL, headers: [String: String] = [:], completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
        executeRequest(
            url,
            f: {(req) -> (Void) in
                req.HTTPMethod = HttpClient.GET
                for (key, value) in headers {
                    req.addValue(value, forHTTPHeaderField: key)
                }
            },
            completionHandler: completionHandler)
    }
    
    func toJson(data: NSData) {
        //let data = "".dataUsingEncoding(NSUTF8StringEncoding)!
        var error: NSError?
        let anyObj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error)
        
    }

    func postJSON2(url: String, payload: AnyObject, onResponse: (NSData, NSHTTPURLResponse) -> Void, onError: (NSData, NSError) -> Void) {
        postJSON(NSURL(string: url)!, jsonObj: payload, completionHandler: handlify(onResponse, onError: onError))
    }

    func postJSON(url: NSURL, jsonObj: AnyObject, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
        executeRequest(
            url,
            f: {
                (req) -> Void in
                req.HTTPMethod = HttpClient.POST
                req.addValue(HttpClient.JSON, forHTTPHeaderField: HttpClient.ACCEPT)
                req.addValue(HttpClient.JSON, forHTTPHeaderField: HttpClient.CONTENT_TYPE)
                var err: NSError?
                req.HTTPBody = NSJSONSerialization.dataWithJSONObject(jsonObj, options: nil, error: &err)
            },
            completionHandler: completionHandler)
    }
    
    func executeRequest(
        url: NSURL,
        f: NSMutableURLRequest -> Void,
        completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
        let req = NSMutableURLRequest(URL: url)
        f(req)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(req, completionHandler: completionHandler)
        task.resume()
    }

    func handlify(onResponse: (NSData, NSHTTPURLResponse) -> Void, onError: (NSData, NSError) -> Void) -> ((NSData!, NSURLResponse!, NSError!) -> Void)? {
        return {
            (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if let error = error {
                onError(data, error)
            }
            if let httpResponse = response as? NSHTTPURLResponse {
                onResponse(data, httpResponse)
            }
        }
    }
}
