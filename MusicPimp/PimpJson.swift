//
//  PimpJson.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 08/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

open class PimpJson {
    public static let sharedInstance = PimpJson()
    
    static let ID = "id", SERVER_TYPE = "serverType", NAME = "name", PROTO = "proto", ADDRESS = "address", PORT = "port", USERNAME = "username", PASSWORD = "password", SSL = "ssl"
    static let RELATIVE_PATH = "relativePath", DESTINATION_URL = "destinationUrl", TASK = "task", TASKS = "tasks", SESSION = "session", SESSIONS = "sessions"
}

