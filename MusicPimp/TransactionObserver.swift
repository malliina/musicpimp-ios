import Foundation
import StoreKit

class TransactionObserver: NSObject, SKPaymentTransactionObserver {
  let log = LoggerFactory.shared.pimp(TransactionObserver.self)
  static let sharedInstance = TransactionObserver()
  @Published var events: SKPaymentTransaction?

  func paymentQueue(
    _ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    for transaction in transactions {
      let state = transaction.transactionState
      switch state {
      case SKPaymentTransactionState.purchasing:
        onPurchasing(transaction)
        break
      case SKPaymentTransactionState.purchased:
        onPurchased(transaction)
        break
      case SKPaymentTransactionState.deferred:
        onDeferred()
        break
      case SKPaymentTransactionState.failed:
        onFailed()
        break
      case SKPaymentTransactionState.restored:
        onRestored(transaction)
        break
      @unknown default:
        log.error("Unexpected transactions state \(transaction.transactionState)")
        break
      }
      events = transaction
      if state == .purchased || state == .failed || state == .restored {
        finishTransaction(transaction)
      }
    }
  }

  func paymentQueue(
    _ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct
  ) -> Bool {
    false
  }

  func finishTransaction(_ transaction: SKPaymentTransaction) {
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  func onPurchasing(_ transaction: SKPaymentTransaction) {

  }

  func onPurchased(_ transaction: SKPaymentTransaction) {
    enable(transaction)
  }

  func onDeferred() {

  }

  func onFailed() {

  }

  func onRestored(_ transaction: SKPaymentTransaction) {
    enable(transaction)
  }

  fileprivate func enable(_ transaction: SKPaymentTransaction) {
    if transaction.payment.productIdentifier == PurchaseHelper.PremiumId {
      PimpSettings.sharedInstance.isUserPremium = true
    }
  }
}
