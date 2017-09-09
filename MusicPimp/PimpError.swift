//
//  PimpEither.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

enum PimpError {
    case parseError(JsonError)
    case responseFailure(ResponseDetails)
    case networkFailure(RequestFailure)
    case simpleError(ErrorMessage)
    
    static func stringify(_ error: PimpError) -> String {
        return PimpErrorUtil.stringify(error)
    }
    
    static func simple(_ message: String) -> PimpError {
        return PimpError.simpleError(ErrorMessage(message: message))
    }
}

class PimpErrorUtil {
    static func stringify(_ error: PimpError) -> String {
        switch error {
        case .parseError(let json):
            switch json {
            case .missing(let key):
                return "Key not found: '\(key)'."
            case .invalid(let key, let actual):
                return "Invalid '\(key)' value: '\(actual)'."
            case .notJson( _):
                return "Invalid response format. Expected JSON."
            }
        case .responseFailure(let details):
            let code = details.code
            switch code {
            case 400: // Bad Request
                return "A network request was rejected."
            case 401:
                return "Check your username/password."
            case 404:
                return "Resource not found: \(details.resource)."
            default:
                if let message = details.message {
                    return "Error code: \(code), message: \(message)"
                } else {
                    return "Error code: \(code)."
                }
            }
        case .networkFailure( _):
            return "A network error occurred."
        case .simpleError(let message):
            return message.message
        }
    }
    
    static func stringifyDetailed(_ error: PimpError) -> String {
        switch error {
        case .networkFailure(let request):
            return "Unable to connect to \(request.url.description), status code \(request.code)."
        default:
            return stringify(error)
        }
    }
}

class ResponseDetails {
    let resource: String
    let code: Int
    let message: String?
    
    init(resource: String, code: Int, message: String?) {
        self.resource = resource
        self.code = code
        self.message = message
    }
}

class RequestFailure {
    let url: URL
    let code: Int
    let data: Data?
    
    init(url: URL, code: Int, data: Data?) {
        self.url = url
        self.code = code
        self.data = data
    }
}

class ErrorMessage {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}
