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
    case ResponseFailure(String, Int, String?)
    case NetworkFailure(RequestFailure)
    case SimpleError(ErrorMessage)
    
    static func stringify(error: PimpError) -> String {
        return PimpErrorUtil.stringify(error)
    }
}
class PimpErrorUtil {
    static func stringify(error: PimpError) -> String {
        switch error {
        case .ParseError:
            return "Parse error"
        case .ResponseFailure(let resource, let code, let message):
            switch code {
            case 400: // Bad Request
                return "A network request was rejected"
            case 401:
                return "Check your username/password"
            case 404:
                return "Resource not found: \(resource)"
            default:
                if let message = message {
                    return "Error code: \(code), message: \(message)"
                } else {
                    return "Error code: \(code)"
                }
            }
        case .NetworkFailure(let failure):
            return "Unable to connect"
        case .SimpleError(let message):
            return message.message
        }
    }
}

class RequestFailure {
    let data: NSData
    init(data: NSData) {
        self.data = data
    }
}

class ErrorMessage {
    let message: String
    init(message: String) {
        self.message = message
    }
}