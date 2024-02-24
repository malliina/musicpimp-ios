import Foundation
import os.log

class Logger {
  private let osLog: OSLog

  init(_ subsystem: String, category: String) {
    osLog = OSLog(subsystem: subsystem, category: category)
  }

  func info(_ message: String) {
    write(message, .info)
  }

  func warn(_ message: String) {
    write(message, .default)
  }

  func error(_ message: String) {
    write(message, .error)
  }

  func write(_ message: String, _ level: OSLogType) {
    os_log("%@", log: osLog, type: level, message)
  }
}

class LoggerFactory {
  static let shared = LoggerFactory(packageName: "org.musicpimp.MusicPimp")

  let packageName: String

  init(packageName: String) {
    self.packageName = packageName
  }

  func network<Subject>(_ subject: Subject) -> Logger {
    base("Network", category: subject)
  }

  func system<Subject>(_ subject: Subject) -> Logger {
    base("System", category: subject)
  }

  func view<Subject>(_ subject: Subject) -> Logger {
    base("Views", category: subject)
  }

  func vc<Subject>(_ subject: Subject) -> Logger {
    base("ViewControllers", category: String(describing: subject))
  }

  func pimp<Subject>(_ subject: Subject) -> Logger {
    base("MusicPimp", category: String(describing: subject))
  }

  func base<Subject>(_ suffix: String, category: Subject) -> Logger {
    Logger("\(packageName).\(suffix)", category: String(describing: category))
  }
}
