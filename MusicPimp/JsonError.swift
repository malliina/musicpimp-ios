
import Foundation

enum JsonError: Error {
    case notJson(Data)
    case missing(String)
    case invalid(String, Any)
    
    var message: String { return JsonError.stringify(json: self) }
    
    static func stringify(json: JsonError) -> String {
        switch json {
        case .missing(let key):
            return "Key not found: '\(key)'."
        case .invalid(let key, let actual):
            return "Invalid '\(key)' value: '\(actual)'."
        case .notJson( _):
            return "Invalid response format. Expected JSON."
        }
    }
}
