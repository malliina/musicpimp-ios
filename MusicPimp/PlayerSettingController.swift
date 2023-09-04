
import Foundation
import UIKit

class PlayerSettingController: EndpointSelectController {
    let manager = PlayerManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PLAYERS"
    }
    
    override func use(endpoint: Endpoint) {
        let _ = manager.use(endpoint: endpoint)
    }
    
    override func loadActive() -> Endpoint {
        manager.loadActive()
    }
}
