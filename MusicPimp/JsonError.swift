//
//  JsonError.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 09/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

enum JsonError: Error {
    case notJson(Data)
    case missing(String)
    case invalid(String, Any)
}
