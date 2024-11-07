import SwiftUI

struct SettingsView: View {
  @StateObject private var vm: SettingsVM = SettingsVM()
  
  var body: some View {
    SettingsViewInternal(vm: vm)
  }
}

struct SettingsViewInternal<T: SettingsVMLike>: View {
  @ObservedObject var vm: T
  
  var body: some View {
    List {
      Section("PLAYBACK") {
        NavigationLink {
          SourceSettingRepresentable()
        } label: {
          horizontalTexts(title: "Music source", detail: vm.libraryName)
        }
        NavigationLink {
          PlayerSettingRepresentable()
        } label: {
          horizontalTexts(title: "Play music on", detail: vm.playerName)
        }
      }
      .listRowBackground(colors.background)
      Section("STORAGE") {
        NavigationLink {
          CacheTableRepresentable()
        } label: {
          horizontalTexts(title: "Cache", detail: vm.currentLimitDescription)
        }
      }
      .listRowBackground(colors.background)
      Section("ALARM CLOCK") {
        NavigationLink {
          AlarmsRepresentable()
        } label: {
          Text("Alarms")
        }
      }
      .listRowBackground(colors.background)
      Section("ABOUT") {
        NavigationLink {
          IAPRepresentable()
        } label: {
          Text("MusicPimp Premium")
        }
        NavigationLink {
          CreditsView()
        } label: {
          Text("Credits")
        }
      }
      .listRowBackground(colors.background)
    }
    
    .listStyle(.plain)
    .background(colors.background)
    .navigationTitle("SETTINGS")
  }
  
  func horizontalTexts(title: String, detail: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(detail)
    }
  }
}

struct SettingsPreview: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    NavigationView {
      SettingsViewInternal(vm: PreviewSettingsVM())
    }
  }
}
