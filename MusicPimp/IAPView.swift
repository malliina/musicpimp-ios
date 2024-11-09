import SwiftUI

struct IAPView: View {
  @StateObject var vm: IAPVM = IAPVM.shared
  
  var body: some View {
    VStack {
      Spacer()
      Text(vm.status)
        .padding()
      if vm.showPurchaseViews {
        Button("Purchase MusicPimp Premium") {
          vm.purchase()
        }
        Spacer()
        Text("Already purchased?")
          .padding()
        Button("Restore MusicPimp Premium") {
          vm.restore()
        }
        .padding(.bottom)
        .padding(.bottom)
      } else {
        Spacer()
      }
    }
    .task {
      await vm.onAppear()
    }
    .frame(maxWidth: .infinity)
    .navigationTitle("MUSICPIMP PREMIUM")
    .background(colors.background)
  }
}

struct IAPPreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    IAPView()
  }
}
