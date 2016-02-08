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
    var changes: Event<Setting> { get }
    
    func save(contents: String, key: String) -> ErrorMessage?
    
    func load(key: String) -> String?
}
