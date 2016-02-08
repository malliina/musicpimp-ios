//
//  PurchaseHelper.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 09/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import StoreKit

class PurchaseHelper: NSObject {
    static let sharedInstance = PurchaseHelper()
    static let PremiumId = "org.musicpimp.premium"

    var request: SKProductsRequest? = nil
    
    func validateProductIdentifiers() {
        let request = SKProductsRequest(productIdentifiers: [ PurchaseHelper.PremiumId ])
        self.request = request
        request.delegate = self
        request.start()
    }
}

extension PurchaseHelper: SKProductsRequestDelegate {
    @objc func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        let premiumId = PurchaseHelper.PremiumId
        let products = response.products
        for product in products {
            Log.info("Got product ID \(product.productIdentifier)")
        }
        let invalidIdentifiers = response.invalidProductIdentifiers
        for invalidIdentifier in invalidIdentifiers {
            Log.error("Invalid product ID \(invalidIdentifier)")
        }
        if invalidIdentifiers.contains(premiumId) {
            Log.error("MusicPimp Premium is not available")
        } else {
            Log.info("App Store has MusicPimp Premium")
        }
    }
}
