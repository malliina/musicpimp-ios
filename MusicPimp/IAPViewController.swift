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
import RxSwift

fileprivate extension Selector {
    static let purchaseClicked = #selector(IAPViewController.purchase)
    static let restoreClicked = #selector(IAPViewController.restore)
}

class IAPViewController: PimpViewController {
    let log = LoggerFactory.shared.vc(IAPViewController.self)
    static let loadingText = "Loading products..."
    let statusLabel = PimpLabel.centered(text: IAPViewController.loadingText)
    let purchaseButton = PimpButton.with(title: "Purchase MusicPimp Premium")
    let alreadyPurchasedLabel = PimpLabel.centered(text: "Already purchased?")
    let restoreButton = PimpButton.with(title: "Restore MusicPimp Premium")
    var disposable: RxSwift.Disposable? = nil

    var products: [SKProduct] = []
    var premiumProduct: SKProduct? = nil
    var invalidIdentifiers: [String] = []
    var request: SKProductsRequest? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "MUSICPIMP PREMIUM"
        purchaseButton.addTarget(self, action: .purchaseClicked, for: .touchUpInside)
        restoreButton.addTarget(self, action: .restoreClicked, for: .touchUpInside)
        togglePurchaseViews(true)
        disposable = TransactionObserver.sharedInstance.events.subscribe(onNext: { (transaction) in
            self.onTransactionUpdate(transaction)
        })
        initUI()
    }
    
    func initUI() {
        addSubviews(views: [statusLabel, purchaseButton, alreadyPurchasedLabel, restoreButton])
        statusLabel.snp.makeConstraints { make in
            make.topMargin.greaterThanOrEqualToSuperview().offset(16)
            make.leadingMargin.trailingMargin.equalToSuperview()
        }
        purchaseButton.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(32)
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.centerY.equalToSuperview().priority(600)
        }
        alreadyPurchasedLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(purchaseButton.snp.bottom).offset(32)
            make.leadingMargin.trailingMargin.centerX.equalToSuperview()
        }
        restoreButton.snp.makeConstraints { make in
            make.top.equalTo(alreadyPurchasedLabel.snp.bottom).offset(32)
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func onTransactionUpdate(_ transaction: SKPaymentTransaction) {
        switch (transaction.transactionState) {
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
            log.info("Purchase failed. Domain: \(domain)")
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
    
    @objc func purchase() {
        log.info("Starting purchase procedure...")
        if let premiumProduct = premiumProduct {
            let paymentRequest = SKMutablePayment(product: premiumProduct)
            SKPaymentQueue.default().add(paymentRequest)
        }
    }
    
    @objc func restore() {
//        statusLabel.text = "Restoring..."
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func loadProductIdentifiers() {
        statusLabel.text = IAPViewController.loadingText
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
                log.info("Got product ID \(product.productIdentifier)")
            }
            let invalidIdentifiers = response.invalidProductIdentifiers
            for invalidIdentifier in invalidIdentifiers {
                log.error("Invalid product ID \(invalidIdentifier)")
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
                log.error(msg)
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
