//
//  Log.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import os.log

open class Log {
    @available(iOS 10.0, *)
    static let log = OSLog(subsystem: "org.musicpimp", category: "general")
    
//    static func info<T>(_ msg: T) -> Void {
//        if #available(iOS 10.0, *) {
//            os_log("%@", log: log, type: .info, "\(msg)")
//        } else {
//            print(msg)
//        }
//        
//    }
//    
//    static func error<T>(_ msg: T) -> Void {
//        if #available(iOS 10.0, *) {
//            os_log("%@", log: log, type: .error, "\(msg)")
//        } else {
//            print(msg)
//        }
//    }
}

class Logger {
    private let osLog: OSLog?
    
    init(_ subsystem: String, category: String) {
        if #available(iOS 10.0, *) {
            osLog = OSLog(subsystem: subsystem, category: category)
        } else {
            osLog = nil
        }
    }
    
    func info(_ message: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", log: osLog ?? .default, type: .info, message)
        } else {
            print(message)
        }
    }
    
    func error(_ message: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", log: osLog ?? .default, type: .error, message)
        } else {
            print(message)
        }
    }
}

class LoggerFactory {
    static func network(_ className: String) -> Logger {
        return pimp(className, category: "Network")
    }
    
    static func system(_ className: String) -> Logger {
        return pimp(className, category: "System")
    }
    
    static func view(_ className: String) -> Logger {
        return pimp("Views.\(className)", category: "Views")
    }
    
    static func vc(_ className: String) -> Logger {
        return pimp("ViewControllers.\(className)", category: "ViewControllers")
    }
    
    static func pimp(_ suffix: String, category: String) -> Logger {
        return Logger("org.musicpimp.MusicPimp.\(suffix)", category: category)
    }
}
