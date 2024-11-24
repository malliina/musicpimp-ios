import Combine
import Foundation
import QuartzCore
import StoreKit

class IAPVM: NSObject, ObservableObject {
  static let shared = IAPVM()
  
  let log = LoggerFactory.shared.vc(IAPVM.self)
  
  private var products: [SKProduct] = []
  var premiumProduct: SKProduct? {
    products.find { $0.productIdentifier == PurchaseHelper.PremiumId }
  }
  static let loadingText = "Loading products..."
  @Published var status: String = IAPVM.loadingText
  @Published var showPurchaseViews: Bool = false
  
  private var request: SKProductsRequest? = nil
  
  override init() {
    super.init()
    Task {
      for await transaction in TransactionObserver.sharedInstance.$events.nonNilValues() {
        onTransactionUpdate(transaction)
      }
    }
  }
  
  func purchase() {
    log.info("Starting purchase procedure...")
    if let premiumProduct = premiumProduct {
      let paymentRequest = SKMutablePayment(product: premiumProduct)
      SKPaymentQueue.default().add(paymentRequest)
    }
  }
  
  func restore() {
    log.info("Restoring purchase...")
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
  
  func onAppear() async {
    if PimpSettings.sharedInstance.isUserPremium {
      await showUserOwnsPremium()
    } else {
      await on(status: IAPVM.loadingText)
      let request = SKProductsRequest(productIdentifiers: [PurchaseHelper.PremiumId])
      self.request = request
      request.delegate = self
      request.start()
    }
  }
  
  func onTransactionUpdate(_ transaction: SKPaymentTransaction) {
    Task {
      switch transaction.transactionState {
      case SKPaymentTransactionState.purchasing:
        await on(status: "Purchasing...")
        break
      case SKPaymentTransactionState.purchased:
        await showUserOwnsPremium()
        break
      case SKPaymentTransactionState.deferred:
        await on(status: "Deferred...")
        break
      case SKPaymentTransactionState.failed:
        let domain = transaction.error?._domain ?? "unknown domain"
        log.info("Purchase failed. Domain: \(domain)")
        await on(status: "Purchase failed.")
        break
      case SKPaymentTransactionState.restored:
        await showUserOwnsPremium()
        break
      @unknown default:
        log.error("Unknown transaction state.")
        ()
      }
    }
  }
  
  @MainActor
  private func showUserOwnsPremium() {
    on(status: "You own MusicPimp Premium! Congratulations.")
    showPurchaseViews = false
  }
  
  @MainActor
  private func on(showPurchaseViews: Bool) {
    self.showPurchaseViews = showPurchaseViews
  }
  
  @MainActor private func on(status: String) {
    self.status = status
  }
  
  func formatPrice(_ product: SKProduct) -> String? {
    let formatter = NumberFormatter()
    formatter.formatterBehavior = NumberFormatter.Behavior.behavior10_4
    formatter.numberStyle = NumberFormatter.Style.currency
    formatter.locale = product.priceLocale
    return formatter.string(from: product.price)
  }
}

extension IAPVM: SKProductsRequestDelegate {
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    if request == self.request {
      products = response.products
      for product in products {
        log.info("Got product ID \(product.productIdentifier)")
      }
      let invalidIdentifiers = response.invalidProductIdentifiers
      for invalidIdentifier in invalidIdentifiers {
        log.error("Invalid product ID \(invalidIdentifier)")
      }
      Task {
        if let premiumProduct = premiumProduct {
          let price = formatPrice(premiumProduct) ?? "a price"
          await on(status: "MusicPimp Premium unlocks unlimited playback and is available for \(price).")
          await on(showPurchaseViews: true)
        } else {
          let msg = "MusicPimp Premium is not available. Try again later."
          log.error(msg)
          await on(status: msg)
        }
      }
    }
  }
}
