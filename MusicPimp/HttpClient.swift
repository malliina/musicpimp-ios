//
// Created by Michael Skogberg on 15/02/15.
// Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class HttpClient {
    static let JSON = "application/json", CONTENT_TYPE = "Content-Type", ACCEPT = "Accept", GET = "GET", POST = "POST", AUTHORIZATION = "Authorization", BASIC = "Basic"

    static func basicAuthValue(username: String, password: String) -> String {
        let encodable = "\(username):\(password)"
        let encoded = encodeBase64(encodable)
        return "\(HttpClient.BASIC) \(encoded)"
    }
    
    static func authHeader(word: String, unencoded: String) -> String {
        let encoded = HttpClient.encodeBase64(unencoded)
        return "\(word) \(encoded)"
    }
    
    static func encodeBase64(unencoded: String) -> String {
        return unencoded.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    }
    
    func get(url: String, headers: [String: String] = [:], onResponse: (NSData, NSHTTPURLResponse) -> Void, onError: RequestFailure -> Void) {
        let nsURL = NSURL(string: url)!
        get(nsURL, headers: headers) { (data, response, error) -> Void in
            if let error = error {
                onError(RequestFailure(url: nsURL, code: error.code, data: data))
            } else if let httpResponse = response as? NSHTTPURLResponse, data = data {
                onResponse(data, httpResponse)
            } else {
                Log.error("Unable to interpret HTTP response to URL \(url)")
            }
        }
    }
    func get(url: NSURL, headers: [String: String] = [:], completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
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
        let nsURL = NSURL(string: url)!
        postJSON(nsURL, headers: headers, jsonObj: payload) { (data, response, error) -> Void in
            if let error = error {
                onError(RequestFailure(url: nsURL, code: error.code, data: data))
            } else if let httpResponse = response as? NSHTTPURLResponse, data = data {
                onResponse(data, httpResponse)
            } else {
                Log.error("Unable to interpret HTTP response to URL \(url)")
            }
        }
    }

    func postJSON(url: NSURL, headers: [String: String] = [:], jsonObj: AnyObject, completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        executeRequest(
            url,
            f: { (req) -> (Void) in
                req.HTTPMethod = HttpClient.POST
                for (key, value) in headers {
                    req.addValue(value, forHTTPHeaderField: key)
                }
                //let isValid = NSJSONSerialization.isValidJSONObject(jsonObj)
                let body: NSData? = try? NSJSONSerialization.dataWithJSONObject(jsonObj, options: [])
                req.HTTPBody = body
            },
            completionHandler: completionHandler)
    }
    
    func executeRequest(
        url: NSURL,
        f: NSMutableURLRequest -> Void,
        completionHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)) {
        let req = NSMutableURLRequest(URL: url)
        req.timeoutInterval = NSTimeInterval.abs(5)
        f(req)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(req, completionHandler: completionHandler)
        task.resume()
    }
}

