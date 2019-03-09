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
    
    func decode<T: Decodable>(_ t: T.Type) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(t, from: data)
    }
    
    init(http: HTTPURLResponse, data: Data) {
        self.http = http
        self.data = data
    }
}
