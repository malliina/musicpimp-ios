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
    fileprivate let request: NSMutableURLRequest
    var isConnected = false
    
    var onOpenCallback: (() -> Void)? = nil
    var onOpenErrorCallback: ((Error) -> Void)? = nil
    
    init(baseURL: String, headers: [String: String]) {
        self.baseURL = baseURL
        let url = Util.url(baseURL)
        request = NSMutableURLRequest(url: url)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        super.init()
    }
    
    func open(_ onOpen: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        close()
        let webSocket = SRWebSocket(urlRequest: request as URLRequest!)
        webSocket?.delegate = self
        self.socket = webSocket
        self.onOpenCallback = onOpen
        self.onOpenErrorCallback = onError
        webSocket?.open()
        info("Connecting to \(baseURL)...")
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        if let message = message as? String {
            info("Got message \(message)")
        } else {
            info("Got data \(message)")
        }
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        if webSocket != self.socket {
            return
        }
        isConnected = true
        info("Socket opened to \(baseURL)")
        if let onOpen = onOpenCallback {
            onOpen(())
            onOpenCallback = nil
            onOpenErrorCallback = nil
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isConnected = false
        info("Error for connection to \(baseURL)")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        isConnected = false
        info("Connection failed to \(baseURL)")
        if let onError = onOpenErrorCallback {
            onError(error)
            onOpenCallback = nil
            onOpenErrorCallback = nil
        }
    }
    
    func info(_ s: String) {
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
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        Log.info("Closed socket to \(baseURL), code: \(code)")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        info("Failed socket to \(baseURL)")
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        info("Got message from \(baseURL): \(message)")
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        info("Opened socket to \(baseURL)")
    }
    
    func info(_ s: String) {
        Log.info(s)
    }
}
