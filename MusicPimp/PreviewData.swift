class PreviewSource: EndpointSource {
  static let e1 = Endpoint(id: "id1", serverType: .cloud, name: "Cloud", ssl: true, address: "todo", port: 1111, username: "test", password: "test")
  static let e2 = Endpoint(id: "id2", serverType: .cloud, name: "pi", ssl: true, address: "todo", port: 1111, username: "test", password: "test")
  static let testEndpoints: [Endpoint] = [e1, e2]
  
  @Published var es: [Endpoint] = [e1, e2]
  var endpointsPublished: Published<[Endpoint]>.Publisher {
    $es
  }
  
  func endpoints() -> [Endpoint] {
    [ Endpoint.Local]
  }
  
  func loadActive() -> Endpoint {
    PreviewSource.e1
  }
  
  func use(endpoint: Endpoint) async {}
  
  func remove(id: String) async -> [Endpoint] { [] }
}
