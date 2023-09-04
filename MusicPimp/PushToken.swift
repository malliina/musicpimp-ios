
import Foundation

struct PushToken: IdCodable {
    let token: String
    var value: String { return token }
    
    init(token: String) {
        self.token = token
    }
    
    init(id: String) {
        self.token = id
    }
}
