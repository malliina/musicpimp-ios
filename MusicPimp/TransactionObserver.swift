//
//  TransactionObserver.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 30/01/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import StoreKit

class TransactionObserver : NSObject, SKPaymentTransactionObserver {
    static let sharedInstance = TransactionObserver()
    let events = Event<SKPaymentTransaction>()
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let state = transaction.transactionState
            switch(state) {
            case SKPaymentTransactionState.Purchasing:
                onPurchasing(transaction)
                break
            case SKPaymentTransactionState.Purchased:
                onPurchased(transaction)
                break
            case SKPaymentTransactionState.Deferred:
                onDeferred()
                break
            case SKPaymentTransactionState.Failed:
                onFailed()
                break
            case SKPaymentTransactionState.Restored:
                onRestored(transaction)
                break
//            default:
//                Log.error("Unexpected transactions state \(transaction.transactionState)")
//                break
            }
            events.raise(transaction)
            if state == .Purchased || state == .Failed || state == .Restored {
                finishTransaction(transaction)
            }
        }
    }
    
    func finishTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    func onPurchasing(transaction: SKPaymentTransaction) {
        
    }
    
    func onPurchased(transaction: SKPaymentTransaction) {
        enable(transaction)
    }
    
    func onDeferred() {
        
    }
    
    func onFailed() {
        
    }
    
    func onRestored(transaction: SKPaymentTransaction) {
        enable(transaction)
    }
    
    private func enable(transaction: SKPaymentTransaction) {
        if transaction.payment.productIdentifier == PurchaseHelper.PremiumId {
            PimpSettings.sharedInstance.isUserPremium = true
        }
    }
}
