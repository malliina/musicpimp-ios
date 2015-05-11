//
//  Persistence.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

protocol Persistence {
    //typealias ErrorMessage = String
    func save(contents: String, key: String) -> String?
    func load(key: String) -> String?
}
