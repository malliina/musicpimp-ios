//
//  PimpSocket.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

// Web socket that supports reconnects
class PlayerSocket: NSObject, SRWebSocketDelegate {
    
    var socket: SRWebSocket? = nil
    let baseURL: String
    private let request: NSMutableURLRequest
    var isConnected = false
    
    init(baseURL: String, headers: [String: String]) {
        self.baseURL = baseURL
        let url = PlayerManager.toURL(baseURL)
        request = NSMutableURLRequest(URL: url)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        super.init()
    }
    func open() {
        close()
        let webSocket = SRWebSocket(URLRequest: request)
        webSocket.delegate = self
        self.socket = webSocket
        webSocket.open()
        info("Connecting to \(baseURL)...")
    }
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        if let message = message as? String {
            info("Got string")
        }
        info("Got message: \(message)")
    }
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        isConnected = true
        info("Socket opened to \(baseURL)")
    }
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isConnected = false
        info("Error for connection to \(baseURL)")
    }
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        isConnected = false
        info("Connection failed to \(baseURL)")
    }
    func info(s: String) {
        Log.info(s)
    }
    func close() {
        // disposes of any previous socket
        if let socket = socket {
            socket.delegate = LoggingSRSocketDelegate(baseURL: self.baseURL)
            socket.close()
            self.socket = nil
        }
        isConnected = false
    }
}

class LoggingSRSocketDelegate: NSObject, SRWebSocketDelegate {
    let baseURL: String
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        Log.info("Closed socket to \(baseURL), code: \(code)")
    }
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        info("Failed socket to \(baseURL)")
    }
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        info("Got message from \(baseURL): \(message)")
    }
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        info("Opened socket to \(baseURL)")
    }
    func info(s: String) {
        Log.info(s)
    }
}
