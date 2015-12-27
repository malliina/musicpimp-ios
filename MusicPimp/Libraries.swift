//
//  Libraries.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 18/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class Libraries {
    static func fromEndpoint(e: Endpoint) -> LibraryType {
        if e.id == Endpoint.Local.id {
            return LocalLibrary.sharedInstance
        } else {
            return PimpLibrary(endpoint: e, client: PimpHttpClient(baseURL: e.httpBaseUrl, authValue: e.authHeader))
        }
    }
}
