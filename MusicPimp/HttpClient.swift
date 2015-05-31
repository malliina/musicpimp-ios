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
    func get(url: String, headers: [String: String] = [:], onResponse: (NSData, NSHTTPURLResponse) -> Void, onError: RequestFailure -> Void) {
        get(NSURL(string: url)!, headers: headers) { (data, response, error) -> Void in
            if let error = error {
                onError(RequestFailure(data: data))
            }
            if let httpResponse = response as? NSHTTPURLResponse {
                onResponse(data, httpResponse)
            }
        }
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
    func postJSON(url: String, headers: [String: String] = [:], payload: AnyObject, onResponse: (NSData, NSHTTPURLResponse) -> Void, onError: RequestFailure -> Void) {
        
        postJSON(NSURL(string: url)!, headers: headers, jsonObj: payload) { (data, response, error) -> Void in
                if let error = error {
                    onError(RequestFailure(data: data))
                }
                if let httpResponse = response as? NSHTTPURLResponse {
                    onResponse(data, httpResponse)
                }
        }
    }

    func postJSON(url: NSURL, headers: [String: String] = [:], jsonObj: AnyObject, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
        executeRequest(
            url,
            f: { (req) -> (Void) in
                req.HTTPMethod = HttpClient.POST
                for (key, value) in headers {
                    req.addValue(value, forHTTPHeaderField: key)
                }
                var err: NSError?
                //let isValid = NSJSONSerialization.isValidJSONObject(jsonObj)
                let body = NSJSONSerialization.dataWithJSONObject(jsonObj, options: nil, error: &err)
                req.HTTPBody = body
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
}

