//
//  PurchaseHelper.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 09/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class PurchaseHelper {
    static let sharedInstance = PurchaseHelper()
    let limiter = Limiter.sharedInstance
    
    func suggestPremium() {
        Log.error("Playback limit of \(limiter.description) reached")
    }
}
