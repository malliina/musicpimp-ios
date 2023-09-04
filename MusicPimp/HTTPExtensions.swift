
import Foundation

extension HTTPURLResponse {
    var isSuccess: Bool {
        return self.statusCode >= 200 && self.statusCode < 300
    }
}

extension URLResponse {
    var isHTTPSuccess: Bool {
        if let r = self as? HTTPURLResponse {
            return r.isSuccess
        }
        return false
    }
}
