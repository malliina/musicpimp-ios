//
//  PimpSocket.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/05/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerSocket: NSObject, SRWebSocketDelegate {
    
    let socket: SRWebSocket
    let baseURL: String
    
    init(baseURL: String, authHeaderValue: String) {
        self.baseURL = baseURL
        let url = PlayerManager.toURL(baseURL)
        let request = NSMutableURLRequest(URL: url)
        request.addValue(authHeaderValue, forHTTPHeaderField: HttpClient.AUTHORIZATION)
        self.socket = SRWebSocket(URLRequest: request)
        super.init()
        self.socket.delegate = self
    }
//    convenience init(baseURL: String, username: String, password: String) {
//        let authValue = HttpClient.basicAuthValue(username, password: password)
//        self.init(baseURL: baseURL, authHeaderValue: authValue)
//    }
    
    func open() {
        self.socket.open()
        info("Connecting to \(baseURL)...")
    }
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        if let message = message as? String {
            info("Got string")
        }
        info("Got message: \(message)")
    }
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        info("Socket opened to \(baseURL)")
    }
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        info("Error for connection to \(baseURL)")
    }
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        info("Connection failed to \(baseURL)")
    }
    func info(s: String) {
        Log.info(s)
    }
    func close() {
        self.socket.close()
    }
}
