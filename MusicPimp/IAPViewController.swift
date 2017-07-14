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

fileprivate extension Selector {
    static let purchaseClicked = #selector(IAPViewController.purchase)
    static let restoreClicked = #selector(IAPViewController.restore)
}

class IAPViewController: PimpViewController {
    let statusLabel = UILabel()
    let purchaseButton = UIButton()
    let alreadyPurchasedLabel = UILabel()
    let restoreButton = UIButton()
    var disposable: Disposable? = nil

    var products: [SKProduct] = []
    var premiumProduct: SKProduct? = nil
    var invalidIdentifiers: [String] = []
    var request: SKProductsRequest? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        purchaseButton.addTarget(self, action: .purchaseClicked, for: .touchUpInside)
        restoreButton.addTarget(self, action: .restoreClicked, for: .touchUpInside)
        togglePurchaseViews(true)
        disposable = TransactionObserver.sharedInstance.events.addHandler(self) { (iap) -> (SKPaymentTransaction) -> () in
            iap.onTransactionUpdate
        }
        initLabel(label: statusLabel, text: "Loading products...")
        initLabel(label: alreadyPurchasedLabel, text: "Already purchased?")
        purchaseButton.setTitle("Purchase MusicPimp Premium", for: .normal)
        restoreButton.setTitle("Restore MusicPimp Premium", for: .normal)
        [purchaseButton, restoreButton].forEach { button in
            button.setTitleColor(PimpColors.tintColor, for: UIControlState.normal)
        }
        initUI()
    }
    
    func initUI() {
        addSubviews(views: [statusLabel, purchaseButton, alreadyPurchasedLabel, restoreButton])
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.topMargin).offset(8)
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
        }
        purchaseButton.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(32)
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
        }
        alreadyPurchasedLabel.snp.makeConstraints { make in
            make.top.equalTo(purchaseButton.snp.bottom).offset(32)
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
        }
        restoreButton.snp.makeConstraints { make in
            make.top.equalTo(alreadyPurchasedLabel.snp.bottom).offset(32)
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
        }
    }
    
    func initLabel(label: UILabel, text: String) {
        label.textColor = PimpColors.titles
        label.text = text
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        //label.textAlignment = .center
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
