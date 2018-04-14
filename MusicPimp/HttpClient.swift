//
// Created by Michael Skogberg on 15/02/15.
// Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class HttpClient {
    private let log = LoggerFactory.shared.network(HttpClient.self)
    static let JSON = "application/json", CONTENT_TYPE = "Content-Type", ACCEPT = "Accept", GET = "GET", POST = "POST", AUTHORIZATION = "Authorization", BASIC = "Basic"

    static func basicAuthValue(_ username: String, password: String) -> String {
        let encodable = "\(username):\(password)"
        let encoded = encodeBase64(encodable)
        return "\(HttpClient.BASIC) \(encoded)"
    }
    
    static func authHeader(_ word: String, unencoded: String) -> String {
        let encoded = HttpClient.encodeBase64(unencoded)
        return "\(word) \(encoded)"
    }
    
    static func encodeBase64(_ unencoded: String) -> String {
        return unencoded.data(using: String.Encoding.utf8)!.base64EncodedString(options: NSData.Base64EncodingOptions())
    }
    
    func get(_ url: URL, headers: [String: String] = [:], onResponse: @escaping (Data, HTTPURLResponse) -> Void, onError: @escaping (RequestFailure) -> Void) {
        get(url, headers: headers) { (data, response, error) -> Void in
            if let error = error {
                onError(RequestFailure(url: url, code: error._code, data: data))
            } else if let httpResponse = response as? HTTPURLResponse, let data = data {
                onResponse(data, httpResponse)
            } else {
                self.log.error("Unable to interpret HTTP response to URL \(url.absoluteString)")
            }
        }
    }
    
    func get(_ url: URL, headers: [String: String] = [:], completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        executeRequest(
            buildRequest(url: url, httpMethod: HttpClient.GET, headers: headers, body: nil),
            completionHandler: completionHandler)
    }
    
    func postJSON(_ url: URL, headers: [String: String] = [:], payload: [String: AnyObject], onResponse: @escaping (Data, HTTPURLResponse) -> Void, onError: @escaping (RequestFailure) -> Void) {
        postJSON(url, headers: headers, jsonObj: payload) { (data, response, error) -> Void in
            if let error = error {
                onError(RequestFailure(url: url, code: error._code, data: data))
            } else if let httpResponse = response as? HTTPURLResponse, let data = data {
                onResponse(data, httpResponse)
            } else {
                self.log.error("Unable to interpret HTTP response to URL \(url.absoluteString)")
            }
        }
    }

    func postJSON(_ url: URL, headers: [String: String] = [:], jsonObj: [String: AnyObject], completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        let req = buildRequest(url: url, httpMethod: HttpClient.POST, headers: headers, body: try? JSONSerialization.data(withJSONObject: jsonObj, options: []))
        executeRequest(
            req,
            completionHandler: completionHandler)
    }
    
    func executeRequest(
        _ req: URLRequest,
        completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
        let session = URLSession.shared
        let task = session.dataTask(with: req, completionHandler: completionHandler)
        task.resume()
    }
    
    func buildRequest(url: URL, httpMethod: String, headers: [String: String], body: Data?) -> URLRequest {
        var req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5)
        req.httpMethod = httpMethod
        for (key, value) in headers {
            req.addValue(value, forHTTPHeaderField: key)
        }
        if let body = body {
            req.httpBody = body
        }
        return req
    }
}
