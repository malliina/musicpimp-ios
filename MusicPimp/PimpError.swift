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
    case ResponseFailure(Int, String?)
    case NetworkFailure(RequestFailure)
    case SimpleError(ErrorMessage)
}
class PimpErrorUtil {
    static func stringify(error: PimpError) -> String {
        switch error {
        case .ParseError: return "Parse error"
        case .ResponseFailure(let code, let message):
            let msg = message ?? "none"
            return "Invalid code: \(code), message: \(msg)"
        case .NetworkFailure(let failure): return "Network failure"
        case .SimpleError(let message): return message.message
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