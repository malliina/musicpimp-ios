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
    
    func executeParsed<T: Decodable>(_ req: URLRequest, to: T.Type) -> Single<T> {
        return executeChecked(req).flatMap { (response) -> Single<T> in
            self.recovered { () -> T in
                try response.decode(to)
            }
        }
    }
    
    func recovered<T>(code: () throws -> T) -> Single<T> {
        do {
            return try Single.just(code())
        } catch let e {
            return Single.error(e)
        }
    }
    
    func executeChecked(_ req: URLRequest) -> Single<HttpResponse> {
        // Fix
        let url = req.url ?? URL(string: "https://www.musicpimp.org")!
        return executeHttp(req).flatMap { self.statusChecked(url, response: $0) }
    }
    
    func executeHttp(_ req: URLRequest) -> Single<HttpResponse> {
        return session.rx.response(request: req).asSingle().flatMap { (result) -> Single<HttpResponse> in
            let (response, data) = result
            return Single.just(HttpResponse(http: response, data: data))
        }
    }
    
    func statusChecked(_ url: URL, response: HttpResponse) -> Single<HttpResponse> {
        if response.isStatusOK {
            return Single.just(response)
        } else {
            self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
            let errorMessage = try? response.decode(FailReason.self).reason
            return Single.error(PimpError.responseFailure(ResponseDetails(resource: url, code: response.statusCode, message: errorMessage)))
        }
    }
    
    func buildGet(url: URL, headers: [String: String] = [:]) -> URLRequest {
        return buildRequest(url: url, httpMethod: HttpClient.GET, headers: headers)
    }
    
    func buildRequestWithBody(url: URL, httpMethod: String, headers: [String: String], body: Data) -> URLRequest {
        var req = buildRequest(url: url, httpMethod: httpMethod, headers: headers)
        req.httpBody = body
        return req
    }
    
    func buildRequest(url: URL, httpMethod: String, headers: [String: String]) -> URLRequest {
        var req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5)
        req.httpMethod = httpMethod
        for (key, value) in headers {
            req.addValue(value, forHTTPHeaderField: key)
        }
        return req
    }
}

struct FailReason: Codable {
    let reason: String
}
