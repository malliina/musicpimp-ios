//
//  PimpUtils.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 26/07/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PimpUtils {
    let endpoint: Endpoint
    
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    // for cloud, keys s, u, p
    func urlFor(_ trackID: String) -> URL {
        return URL(string: "\(endpoint.httpBaseUrl)/tracks/\(trackID)?\(endpoint.authQueryString)")!
    }
}
