import Combine

class SelectEndpointVM: ObservableObject {
  static let libraries = SelectEndpointVM(source: LibraryManager.sharedInstance)
  static let players = SelectEndpointVM(source: PlayerManager.sharedInstance)
  
  private var cancellables: Set<AnyCancellable> = []
  
  @Published var savedEndpoints: [Endpoint] = []
  var endpoints: [Endpoint] {
    [Endpoint.Local] + savedEndpoints
  }
  
  let source: EndpointSource
  
  init(source: EndpointSource) {
    self.source = source
    settings.$endpointsEvent
      .receive(on: RunLoop.main)
      .assign(to: \.savedEndpoints, on: self)
      .store(in: &cancellables)
  }
  
  var active: Endpoint? {
    endpoints.find { e in
      e.id == source.loadActive().id
    }
  }
  
  func use(endpoint: Endpoint) async {
    await source.use(endpoint: endpoint)
  }
  
  func remove(id: String) async {
    let _ = await source.remove(id: id)
  }
}
