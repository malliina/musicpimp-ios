
import Foundation
import StoreKit

class PurchaseHelper: NSObject {
    let log = LoggerFactory.shared.pimp(PurchaseHelper.self)
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
    @objc func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let premiumId = PurchaseHelper.PremiumId
        let products = response.products
        for product in products {
            log.info("Got product ID \(product.productIdentifier)")
        }
        let invalidIdentifiers = response.invalidProductIdentifiers
        for invalidIdentifier in invalidIdentifiers {
            log.error("Invalid product ID \(invalidIdentifier)")
        }
        if invalidIdentifiers.contains(premiumId) {
            log.error("MusicPimp Premium is not available")
        } else {
            log.info("App Store has MusicPimp Premium")
        }
    }
}
