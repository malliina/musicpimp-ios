import SwiftUI

enum EndpointType {
  case source, player
}

enum HttpProto {
  case https, http
}

struct EditEndpointView: View {
  @Environment(\.dismiss) private var dismiss
  
  let endpoint: Endpoint?
  let endpointType: EndpointType
  @StateObject var vm: EditEndpointVM = EditEndpointVM()
  
  @State var segment: ServerType
  @State var cloudId: String
  @State var username: String
  @State var password: String
  @State var name: String
  @State var address: String
  @State var port: String
  @State var proto: HttpProto
  @State var activate: Bool
  
  var isAddNew: Bool { endpoint == nil }
  var isMissingInput: Bool {
    (segment == .cloud && (cloudId.isEmpty)) ||
    (segment == .musicPimp && (name.isEmpty || address.isEmpty || port.isEmpty)) ||
    username.isEmpty || password.isEmpty
  }
  var isValidType: Bool {
    segment == .cloud || segment == .musicPimp
  }
  var endpointLabel: String {
    endpointType == .source ? "music source" : "player"
  }
  
  var currentInput: Endpoint {
    Endpoint(id: endpoint?.id ?? randomId(), serverType: segment, name: segment == .cloud ? cloudId : name, ssl: proto == .https, address: address, port: Int(port) ?? 443, username: username, password: password)
  }
  
  init(endpoint: Endpoint?, endpointType: EndpointType) {
    self.endpoint = endpoint
    self.endpointType = endpointType
    if let endpoint = endpoint {
      segment = endpoint.serverType == .cloud ? .cloud : .musicPimp
      cloudId = endpoint.name
      username = endpoint.username
      password = endpoint.password
      name = endpoint.name
      address = endpoint.address
      port = "\(endpoint.port)"
      proto = endpoint.ssl ? .https : .http
    } else {
      segment = .cloud
      cloudId = ""
      username = ""
      password = ""
      name = ""
      address = ""
      port = "443"
      proto = .https
    }
    activate = true
  }
  
  func randomId() -> String {
    UUID().uuidString
  }
  
  var body: some View {
    ScrollView(.vertical) {
      VStack(alignment: .leading) {
        Picker("Segment", selection: $segment) {
          Text("Cloud").tag(ServerType.cloud)
          Text("MusicPimp").tag(ServerType.musicPimp)
        }
        .pickerStyle(.segmented)
        switch segment {
        case .cloud:
          Text("Cloud ID")
          TextField("Cloud ID", text: $cloudId)
          Text("Username")
          TextField("Username", text: $username)
          Text("Password")
          SecureField("Password", text: $password)
        case .musicPimp:
          Text("Name")
          TextField("Name", text: $name)
          Text("Address")
          TextField("Address", text: $address)
          Text("Port")
          TextField("Port", text: $port)
            .keyboardType(.numberPad)
          Text("Username")
          TextField("Username", text: $username)
          Text("Password")
          SecureField("Password", text: $password)
          Picker("Protocol", selection: $proto) {
            Text("HTTP").tag(HttpProto.http)
            Text("HTTPS").tag(HttpProto.https)
          }
          .pickerStyle(.segmented)
        default:
          fullSizeText("Unsupported server type.")
        }
        if isValidType {
          Toggle("Set as active \(endpointLabel)", isOn: $activate)
          Button {
            Task {
              await vm.test(endpoint: currentInput)
            }
          } label: {
            HStack {
              Spacer()
              Text("Test connectivity")
              Spacer()
            }
            .padding()
          }.disabled(isMissingInput)
          Text(vm.testStatus)
          Spacer()
            .frame(height: 24)
        }
        Spacer()
      }
    }
    .textFieldStyle(PimpTextFieldStyle())
    .frame(maxHeight: .infinity)
    .padding()
    .background(colors.background)
    .colorScheme(.dark)
    .navigationTitle(endpoint != nil ? "Edit endpoint" : "Add endpoint")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Save") {
          let input = currentInput
          Task {
            await vm.save(endpoint: input, activate: activate)
            dismiss()
          }
        }.disabled(isMissingInput)
      }
    }
  }
}

struct EditEndpointPreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    EditEndpointView(endpoint: nil, endpointType: .source)
  }
}
