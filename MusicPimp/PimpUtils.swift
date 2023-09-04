
import Foundation

class PimpUtils {
    let endpoint: Endpoint
    
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    // for cloud, keys s, u, p
    func urlFor(_ trackID: String) -> URL {
        return URL(string: "\(endpoint.httpBaseUrl)/tracks/\(trackID)?\(endpoint.authQueryString)")!
    }
}
