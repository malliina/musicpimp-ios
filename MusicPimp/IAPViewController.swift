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
    var disposable: Disposable? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        togglePurchaseViews(true)
        disposable = TransactionObserver.sharedInstance.events.addHandler(self) { (iap) -> (SKPaymentTransaction) -> () in
            iap.onTransactionUpdate
        }
    }
    
    func onTransactionUpdate(_ transaction: SKPaymentTransaction) {
        switch(transaction.transactionState) {
        case SKPaymentTransactionState.purchasing:
            setStatus("Purchasing...")
            break
        case SKPaymentTransactionState.purchased:
            setStatus("Purchased!")
            showUserOwnsPremium()
            break
        case SKPaymentTransactionState.deferred:
            setStatus("Deferred...")
            break
        case SKPaymentTransactionState.failed:
            let domain = transaction.error?._domain ?? "unknown domain"
            Log.info("Purchase failed. Domain: \(domain)")
            setStatus("Purchase failed.")
            break
        case SKPaymentTransactionState.restored:
            setStatus("Restored.")
            showUserOwnsPremium()
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    func togglePurchaseViews(_ hidden: Bool) {
        Util.onUiThread {
            for view in [self.purchaseButton, self.alreadyPurchasedLabel, self.restoreButton] as [UIView] {
                view.isHidden = hidden
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        request?.cancel()
        request = nil
    }
    
    // Profit!
    @IBAction func purchaseClicked(_ sender: UIButton) {
        purchase()
    }
    
    @IBAction func restoreClicked(_ sender: UIButton) {
        restore()
    }
    
    func purchase() {
        Log.info("Starting purchase procedure...")
        if let premiumProduct = premiumProduct {
            let paymentRequest = SKMutablePayment(product: premiumProduct)
            SKPaymentQueue.default().add(paymentRequest)
        }
    }
    
    func restore() {
//        statusLabel.text = "Restoring..."
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func loadProductIdentifiers() {
        statusLabel.text = "Loading products..."
        let request = SKProductsRequest(productIdentifiers: [ PurchaseHelper.PremiumId ])
        self.request = request
        request.delegate = self
        request.start()
    }
    
    func setStatus(_ text: String) {
        Util.onUiThread {
            self.statusLabel.text = text
        }
    }
}

extension IAPViewController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
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
    
    func formatPrice(_ product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = NumberFormatter.Behavior.behavior10_4
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
}
