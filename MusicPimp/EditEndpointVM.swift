class EditEndpointVM: ObservableObject {
  @Published var testStatus: String = ""
  
  func test(endpoint: Endpoint) async {
    await on(status: "Connecting...")
    let client = Libraries.fromEndpoint(endpoint)
    do {
      let version = try await client.pingAuth()
      await on(status: "\(endpoint.serverType.name) \(version.version) at your service.")
    } catch {
      let msg = errorMessage(endpoint, error: error)
      await on(status: msg)
    }
  }
  
  @MainActor func on(status: String) {
    testStatus = status
  }
  
  func save(endpoint: Endpoint, activate: Bool) async {
    settings.save(endpoint)
    if activate || endpoint.id == libraryManager.loadActive().id {
      let _ = await libraryManager.use(endpoint: endpoint)
    }
  }
  
  private func errorMessage(_ e: Endpoint, error: Error) -> String {
    guard let error = error as? PimpError else { return "Unknown error." }
    switch error {
    case .responseFailure(let details):
      let code = details.code
      switch code {
      case 401: return "Unauthorized. Check your username/password."
      default: return "HTTP error code \(code)."
      }
    case .networkFailure(_):
      return "Unable to connect to \(e.httpBaseUrl)."
    case .parseError:
      return "The response was not understood."
    case .simpleError(let message):
      return message.message
    }
  }
}
