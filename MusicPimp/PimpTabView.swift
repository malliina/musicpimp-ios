import Foundation
import SwiftUI

class PimpTabVM: ObservableObject {
  private var cancellables: Set<Task<(), Never>> = []
  
  @Published var library: LibraryType = LibraryManager.sharedInstance.libraryUpdated
  
  var isLocalLibrary: Bool {
    library.isLocal
  }
  
  init() {
    let task = Task {
      for await newLibrary in LibraryManager.sharedInstance.$libraryUpdated.values {
        await on(library: newLibrary)
      }
    }
    cancellables = [ task ]
  }
  
  @MainActor private func on(library: LibraryType) {
    self.library = library
  }
}

struct PimpTabView: View {
  let tabIconFontSize: Int32 = 24
  
  @StateObject var vm: PimpTabVM = PimpTabVM()

  var body: some View {
    TabView {
      NavigationView {
        LibraryList(id: nil)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("MUSIC")
            .font(.headline)
        }
      }
      .navigationTitle("MUSIC")
      .tabItem {
        Label("Music", systemImage: "music.note.list")
      }
      .ignoresSafeArea(.all)
      NavigationView {
        PlayerView()
      }
      .tabItem {
        Label("Player", systemImage: "play.circle")
      }
      if !vm.isLocalLibrary {
        NavigationView {
          TopLists()
        }
        .tabItem {
          Label("Playlists", systemImage: "list.star")
        }
      }
      NavigationView {
        SettingsView()
          .background(colors.background)
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape.fill")
      }
      .background(colors.background)
    }
    .environment(\.colorScheme, .dark)
  }

  func faImage(_ name: String) -> Image {
    Image(uiImage: icon(name))
  }

  func icon(_ name: String) -> UIImage {
    let image = UIImage(
      icon: name, backgroundColor: .clear, iconColor: .gray, fontSize: tabIconFontSize)
    return image!.withRenderingMode(.alwaysOriginal)
  }
}
