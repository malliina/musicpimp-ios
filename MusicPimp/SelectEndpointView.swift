import SwiftUI
import Combine

struct SelectEndpointView: View {
  let title: String
  let endpointType: EndpointType
  @ObservedObject var vm: SelectEndpointVM
  
  @State var editable: Endpoint? = nil
  @State var isEdit = false
  @State var isAddNew = false
  
  var body: some View {
    ZStack {
      NavigationLink(destination: EditEndpointView(endpoint: editable, endpointType: endpointType), isActive: $isEdit) {
        EmptyView()
      }
      List {
        ForEach(vm.endpoints) { e in
          Button {
            Task {
              await vm.use(endpoint: e)
            }
          } label: {
            HStack {
              Text(e.name)
              if vm.active?.id == e.id {
                Spacer()
                Image(systemName: "checkmark")
              }
            }
          }
          .listRowBackground(colors.background)
          .swipeActions {
            if e.id != Endpoint.Local.id {
              Button {
                editable = e
                isEdit = true
              } label: {
                Text("Edit")
              }
              Button(role: .destructive) {
                Task {
                  await vm.remove(id: e.id)
                }
              } label: {
                Text("Remove")
              }
            }
          }
        }
      }
      .listStyle(.plain)
    }
    .navigationTitle(title)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isAddNew = true
        } label: {
          Image(systemName: "plus")
        }
      }
    }
    .sheet(isPresented: $isAddNew) {
      NavigationView {
        EditEndpointView(endpoint: nil, endpointType: endpointType)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button("Cancel") {
                isAddNew = false
              }
            }
          }
      }
    }
    .background(colors.background)
  }
}

struct SelectEndpointPreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    SelectEndpointView(title: "Sources", endpointType: .source, vm: SelectEndpointVM(source: PreviewSource()))
  }
}
