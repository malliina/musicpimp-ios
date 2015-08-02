//
//  HTTPExtensions.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 28/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
extension NSHTTPURLResponse {
    var isSuccess: Bool {
        return self.statusCode >= 200 && self.statusCode < 300
    }
}

extension NSURLResponse {
    var isHTTPSuccess: Bool {
        if let r = self as? NSHTTPURLResponse {
            return r.isSuccess
        }
        return false
    }
}
