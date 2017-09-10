//
//  Log.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 11/04/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import os.log

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
            write(message, .info)
        } else {
            print(message)
        }
    }
    
    func warn(_ message: String) {
        if #available(iOS 10.0, *) {
            write(message, .default)
        } else {
            print(message)
        }
    }
    
    func error(_ message: String) {
        if #available(iOS 10.0, *) {
            write(message, .error)
        } else {
            print(message)
        }
    }
    
    func write(_ message: String, _ level: OSLogType) {
        if #available(iOS 10.0, *) {
            os_log("%@", log: osLog ?? .default, type: level, message)
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
