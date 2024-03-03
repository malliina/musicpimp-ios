import Foundation

// Web socket that supports reconnects
class PlayerSocket: WebSocketMessageDelegate {
  private let log = LoggerFactory.shared.network(PlayerSocket.self)
  var socket: WebSocket? = nil
  let baseURL: URL
  let headers: [String: String]
  var isConnected: Bool { socket?.isConnected ?? false }

  init(baseURL: URL, headers: [String: String]) {
    self.baseURL = baseURL
    self.headers = headers
  }

  func open() async -> URL {
    close()
    let webSocket = WebSocket(baseURL: baseURL, headers: headers)
    webSocket.delegate = self
    self.socket = webSocket
    return await withCheckedContinuation { cont in
      class OpenClose: OpenCloseDelegate {
        let cont: CheckedContinuation<URL, Never>
        let url: URL
        let log: Logger
        init(cont: CheckedContinuation<URL, Never>, url: URL, log: Logger) {
          self.cont = cont
          self.url = url
          self.log = log
        }
        func onOpen(task: URLSessionWebSocketTask) {
          cont.resume(returning: url)
        }
        func onClose(task: URLSessionWebSocketTask) {
          log.info("Closed connection to '\(url)'.")
        }
      }
      webSocket.openCloseDelegate = OpenClose(cont: cont, url: baseURL, log: log)
      self.log.info("Connecting to '\(self.baseURL)'...")
      webSocket.connect()
    }
  }

  func on(message: String) async {
    log.info("Got message \(message)")
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
