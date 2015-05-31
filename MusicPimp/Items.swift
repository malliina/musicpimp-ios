//
//  Items.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 14/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
protocol Items {
    typealias Element
    
    var items: [Element] { get set }
}
