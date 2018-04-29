//
// Created by Michael Skogberg on 15/02/15.
// Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

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
    
    let session = URLSession.shared
    
    func executeParsedJson<T>(_ req: URLRequest, parse: @escaping (NSDictionary) throws -> T) -> Observable<T> {
        return executeParsed(req) { response in
            try self.asJson(response: response, parse: parse)
        }
    }
    
    func executeParsed<T>(_ req: URLRequest, parse: @escaping (HttpResponse) throws -> T) -> Observable<T> {
        return executeChecked(req).flatMap { (response) -> Observable<T> in
            self.recovered { () -> T in
                try parse(response)
            }
        }
    }
    
    func asJson<T>(response: HttpResponse, parse: (NSDictionary) throws -> T) throws-> T {
        if let json = response.json {
            return try parse(json)
        } else {
            throw PimpError.parseError(JsonError.notJson(response.data))
        }
    }
    
    func recovered<T>(code: () throws -> T) -> Observable<T> {
        do {
            return try Observable.just(code())
        } catch let e {
            return Observable.error(e)
        }
    }
    
    func executeChecked(_ req: URLRequest) -> Observable<HttpResponse> {
        // Fix
        let url = req.url ?? URL(string: "https://www.musicpimp.org")!
        return executeHttp(req).flatMap { self.statusChecked(url, response: $0) }
    }
    
    func executeHttp(_ req: URLRequest) -> Observable<HttpResponse> {
        return session.rx.response(request: req).flatMap { (result) -> Observable<HttpResponse> in
            let (response, data) = result
            return Observable.just(HttpResponse(http: response, data: data))
        }
    }
    
    func statusChecked(_ url: URL, response: HttpResponse) -> Observable<HttpResponse> {
        if response.isStatusOK {
            return Observable.just(response)
        } else {
            self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
            var errorMessage: String? = nil
            if let json = Json.asJson(response.data) as? NSDictionary {
                errorMessage = json[JsonKeys.ERROR] as? String
            }
            return Observable.error(PimpError.responseFailure(ResponseDetails(resource: url, code: response.statusCode, message: errorMessage)))
        }
    }
    
    func buildGet(url: URL, headers: [String: String] = [:]) -> URLRequest {
        return buildRequest(url: url, httpMethod: HttpClient.GET, headers: headers, body: nil)
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
