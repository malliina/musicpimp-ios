//
//  PimpEither.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 16/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

enum PimpError {
    case ParseError
    case ResponseFailure(ResponseDetails)
    case NetworkFailure(RequestFailure)
    case SimpleError(ErrorMessage)
    
    static func stringify(error: PimpError) -> String {
        return PimpErrorUtil.stringify(error)
    }
    
    static func simple(message: String) -> PimpError {
        return PimpError.SimpleError(ErrorMessage(message: message))
    }
}

class PimpErrorUtil {
    static func stringify(error: PimpError) -> String {
        switch error {
        case .ParseError:
            return "Parse error."
        case .ResponseFailure(let details):
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
        case .NetworkFailure( _):
            return "A network error occurred."
        case .SimpleError(let message):
            return message.message
        }
    }
    
    static func stringifyDetailed(error: PimpError) -> String {
        switch error {
        case .NetworkFailure(let request):
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
    let url: NSURL
    let code: Int
    let data: NSData?
    
    init(url: NSURL, code: Int, data: NSData?) {
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
