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

class IAPViewController: PimpViewController {
    static let StoryboardId = "IAPViewController"
    
    var products: [SKProduct] = []
    var premiumProduct: SKProduct? = nil
    var invalidIdentifiers: [String] = []
    var request: SKProductsRequest? = nil
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var purchaseButton: UIButton!
    @IBOutlet var alreadyPurchasedLabel: UILabel!
    @IBOutlet var restoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        togglePurchaseViews(true)
        TransactionObserver.sharedInstance.events.addHandler(self) { (iap) -> SKPaymentTransaction -> () in
            iap.onTransactionUpdate
        }
    }
    
    func onTransactionUpdate(transaction: SKPaymentTransaction) {
        switch(transaction.transactionState) {
        case SKPaymentTransactionState.Purchasing:
            setStatus("Purchasing...")
            break
        case SKPaymentTransactionState.Purchased:
            setStatus("Purchased!")
            showUserOwnsPremium()
            break
        case SKPaymentTransactionState.Deferred:
            setStatus("Deferred...")
            break
        case SKPaymentTransactionState.Failed:
            let domain = transaction.error?.domain ?? "unknown domain"
            Log.info("Purchase failed. Domain: \(domain)")
            setStatus("Purchase failed.")
            break
        case SKPaymentTransactionState.Restored:
            setStatus("Restored.")
            showUserOwnsPremium()
            break
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if PimpSettings.sharedInstance.isUserPremium {
            showUserOwnsPremium()
        } else {
            loadProductIdentifiers()
        }
    }
    
    func showUserOwnsPremium() {
        setStatus("You own MusicPimp Premium! Congratulations.")
        togglePurchaseViews(true)
    }
    
    func togglePurchaseViews(hidden: Bool) {
        Util.onUiThread {
            for view in [self.purchaseButton, self.alreadyPurchasedLabel, self.restoreButton] {
                view.hidden = hidden
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        request?.cancel()
        request = nil
    }
    
    // Profit!
    @IBAction func purchaseClicked(sender: UIButton) {
        purchase()
    }
    
    @IBAction func restoreClicked(sender: UIButton) {
        restore()
    }
    
    func purchase() {
        Log.info("Starting purchase procedure...")
        if let premiumProduct = premiumProduct {
            let paymentRequest = SKMutablePayment(product: premiumProduct)
            SKPaymentQueue.defaultQueue().addPayment(paymentRequest)
        }
    }
    
    func restore() {
//        statusLabel.text = "Restoring..."
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
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
            premiumProduct = products.find { $0.productIdentifier == premiumId }
            if let premiumProduct = premiumProduct {
                let price = formatPrice(premiumProduct) ?? "a price"
                setStatus("MusicPimp Premium unlocks unlimited playback and is available for \(price).")
                togglePurchaseViews(false)
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
