//
//  Persistence.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import RxSwift

protocol Persistence {
    var changes: Observable<Setting> { get }
    
    func save(_ contents: String, key: String) -> ErrorMessage?
    
    func load(_ key: String) -> String?
}
