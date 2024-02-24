import Foundation
import RxSwift

// Web socket that supports reconnects
class PlayerSocket: WebSocketMessageDelegate, OpenCloseDelegate {
  private let log = LoggerFactory.shared.network(PlayerSocket.self)
  var socket: WebSocket? = nil
  let baseURL: URL
  let headers: [String: String]
  var isConnected: Bool { socket?.isConnected ?? false }

  private var openObserver: AnyObserver<Void>? = nil

  init(baseURL: URL, headers: [String: String]) {
    self.baseURL = baseURL
    self.headers = headers
  }

  func open() -> Observable<Void> {
    close()
    let webSocket = WebSocket(baseURL: baseURL, headers: headers)
    webSocket.delegate = self
    webSocket.openCloseDelegate = self
    self.socket = webSocket
    return Observable<Void>.create { observer in
      self.openObserver = observer
      self.log.info("Connecting to '\(self.baseURL)'...")
      webSocket.connect()
      return Disposables.create()
    }
  }

  func on(message: String) {
    log.info("Got message \(message)")
  }

  func onOpen(task: URLSessionWebSocketTask) {
    log.info("Socket opened to \(baseURL)")
    if let observer = openObserver {
      observer.onCompleted()
      openObserver = nil
    }
  }

  func onClose(task: URLSessionWebSocketTask) {
    log.info("Error for connection to \(baseURL)")
  }

  func close() {
    // disposes of any previous socket
    if let socket = socket {
      socket.delegate = nil
      socket.disconnect()
      self.socket = nil
    }
  }
}
