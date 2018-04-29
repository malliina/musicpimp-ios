//
//  PimpSocket.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import SocketRocket
import RxSwift

// Web socket that supports reconnects
class PlayerSocket: NSObject, SRWebSocketDelegate {
    private let log = LoggerFactory.shared.network(PlayerSocket.self)
    var socket: SRWebSocket? = nil
    let baseURL: URL
    fileprivate let request: URLRequest
    var isConnected = false
    
    private var openObserver: AnyObserver<Void>? = nil
    
    init(baseURL: URL, headers: [String: String]) {
        self.baseURL = baseURL
        var baseRequest = URLRequest(url: self.baseURL)
        for (key, value) in headers {
            baseRequest.addValue(value, forHTTPHeaderField: key)
        }
        self.request = baseRequest
        super.init()
    }
    
    func open() -> Observable<Void> {
        close()
        let webSocket = SRWebSocket(urlRequest: request)
        webSocket?.delegate = self
        self.socket = webSocket
        return Observable<Void>.create { observer in
            self.openObserver = observer
            self.log.info("Connecting to '\(self.baseURL)'...")
            webSocket?.open()
            return Disposables.create()
        }
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        if let message = message as? String {
            log.info("Got message \(message)")
        } else {
            log.info("Got data \(message)")
        }
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        if webSocket != self.socket {
            return
        }
        isConnected = true
        log.info("Socket opened to \(baseURL)")
        if let observer = openObserver {
            observer.onCompleted()
            openObserver = nil
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isConnected = false
        log.info("Error for connection to \(baseURL)")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        isConnected = false
        log.info("Connection failed to \(baseURL)")
        if let observer = openObserver {
            observer.onError(error)
            openObserver = nil
        }
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
    let log = LoggerFactory.shared.network(LoggingSRSocketDelegate.self)
    let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        info("Closed socket to \(baseURL), code: \(code)")
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
        log.info(s)
    }
}
