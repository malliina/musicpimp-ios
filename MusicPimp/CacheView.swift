import SwiftUI

struct CacheView: View {
  @StateObject var vm: CacheVM = CacheVM.shared

  let gigOptions: [StorageSize] = [1, 2, 5, 10, 20, 50, 100, 500].map { StorageSize(gigs: $0) }
  
  var body: some View {
    List {
      Text("Deletes locally cached tracks when the specified cache size limit is exceeded.")
        .listRowBackground(colors.background)
      Toggle("Automatic Offline Storage", isOn: $vm.isOn)
        .listRowBackground(colors.background)
      Spacer()
        .frame(height: 32)
        .listRowBackground(colors.background)
      Picker("Size Limit", selection: $vm.limit) {
        ForEach(gigOptions, id: \.description) { gigs in
          Text("\(gigs.toGigs) GB").tag(gigs)
        }
      }
      .listRowBackground(colors.background)
      HStack {
        Text("Current Usage")
        Spacer()
        Text(vm.usedStorage.shortDescription)
      }
      .listRowBackground(colors.background)
      Spacer()
        .frame(height: 32)
        .listRowBackground(colors.background)
      HStack {
        Spacer()
        Button("Delete Offline Storage", role: .destructive) {
          Task {
            await vm.delete()
          }
        }
        Spacer()
      }
      .listRowBackground(colors.background)
      
    }
    .onChange(of: vm.isOn) { isOn in
      vm.on(cacheEnabled: isOn)
    }
    .onChange(of: vm.limit) { limit in
      vm.on(limit: limit)
    }
    .listStyle(.plain)
    .frame(maxWidth: .infinity)
    .navigationTitle("Cache")
    .background(colors.background)
    .task {
      await vm.calculateCacheUsage()
    }
  }
}

struct CachePreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    CacheView()
  }
}

class CacheVM: ObservableObject {
  static let shared = CacheVM()
  
  let log = LoggerFactory.shared.vc(CacheVM.self)
  
  @Published var usedStorage = StorageSize.Zero
  @Published var isOn: Bool = PimpSettings.sharedInstance.cacheEnabled
  @Published var limit: StorageSize = PimpSettings.sharedInstance.cacheLimit
  
  var library: LocalLibrary { LocalLibrary.sharedInstance }
  var currentLimitDescription: String {
    let gigs = settings.cacheLimit.toGigs
    return "\(gigs) GB"
  }
  
  func calculateCacheUsage() async {
    let size = library.size
    await on(storage: size)
  }
  
  func on(cacheEnabled: Bool) {
    log.info("Cache changed to \(cacheEnabled)")
    settings.cacheEnabled = cacheEnabled
  }
  
  func delete() async {
    let _ = await library.deleteContents()
    log.info("Done")
    await calculateCacheUsage()
  }
  
  @MainActor private func on(storage: StorageSize) {
    self.usedStorage = storage
  }
  
  func on(limit: StorageSize) {
    settings.cacheLimit = limit
  }
}
