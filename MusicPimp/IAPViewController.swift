//
//  IAPViewController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import StoreKit
import QuartzCore

class IAPViewController: UIViewController {
    
    var products: [SKProduct] = []
    var invalidIdentifiers: [String] = []
    var request: SKProductsRequest? = nil
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var purchaseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        purchaseButton.backgroundColor = UIColor.greenColor()
        purchaseButton.layer.cornerRadius = 20
        purchaseButton.layer.borderWidth = 2
        purchaseButton.clipsToBounds = true
        purchaseButton.layer.borderColor = UIColor.greenColor().CGColor
        purchaseButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        purchaseButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadProductIdentifiers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        request?.cancel()
        request = nil
    }
    
    // Profit!
    @IBAction func purchaseClicked(sender: UIButton) {
        Log.info("Starting purchase procedure...")
    }
    
    func loadProductIdentifiers() {
        statusLabel.text = "Loading products..."
        let request = SKProductsRequest(productIdentifiers: [ PurchaseHelper.PremiumId ])
        self.request = request
        request.delegate = self
        request.start()
    }
    
    func setStatus(text: String) {
        Util.onUiThread {
            self.statusLabel.text = text
        }
    }
}

extension IAPViewController: SKProductsRequestDelegate {
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        if request == self.request {
            products = response.products
            let premiumId = PurchaseHelper.PremiumId
            for product in products {
                Log.info("Got product ID \(product.productIdentifier)")
            }
            let invalidIdentifiers = response.invalidProductIdentifiers
            for invalidIdentifier in invalidIdentifiers {
                Log.error("Invalid product ID \(invalidIdentifier)")
            }
//            if invalidIdentifiers.contains(premiumId) {
//                let msg = "MusicPimp Premium is not available. Try again later."
//                Log.error(msg)
//                setStatus(msg)
//            }
            let premium = products.find { $0.productIdentifier == premiumId }
            if let premium = premium {
                let price = formatPrice(premium) ?? "a price"
                setStatus("MusicPimp Premium is available for \(price).")
            } else {
                let msg = "MusicPimp Premium is not available. Try again later."
                Log.error(msg)
                setStatus(msg)
            }
        }
    }
    
    func formatPrice(product: SKProduct) -> String? {
        let formatter = NSNumberFormatter()
        formatter.formatterBehavior = NSNumberFormatterBehavior.Behavior10_4
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        formatter.locale = product.priceLocale
        return formatter.stringFromNumber(product.price)
    }
}
