import Foundation
import SwiftUI

struct LibraryRepresentable: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UINavigationController {
    UINavigationController(rootViewController: LibraryContainer())
  }
  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
  }
  typealias UIViewControllerType = UINavigationController
}

struct SettingsRepresentable: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UINavigationController {
    UINavigationController(
      rootViewController: PlaybackContainer(
        title: "SETTINGS", child: SettingsController(), persistentFooter: false))
  }
  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
  }
  typealias UIViewControllerType = UINavigationController
}

struct PhonePlayerRepresentable: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> PlayerParent {
    PlayerParent(persistent: true)
  }
  func updateUIViewController(_ uiViewController: PlayerParent, context: Context) {
  }
  typealias UIViewControllerType = PlayerParent
}

struct PhoneTopListRepresentable: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> TopFlipController {
    TopFlipController(persistent: false)
  }
  func updateUIViewController(_ uiViewController: TopFlipController, context: Context) {
  }
  typealias UIViewControllerType = TopFlipController
}

struct PimpTabView: View {
  let tabIconFontSize: Int32 = 24

  var body: some View {
    TabView {
      //            NavigationView {
      LibraryRepresentable()
        .toolbar {
          ToolbarItem(placement: .principal) {
            Text("MUSIC")
              .font(.headline)
            //                                .foregroundColor(titleColor)
          }
        }
        .navigationTitle("MUSIC")
        .tabItem {
          Label("Music", systemImage: "music.note.list")
        }
        .ignoresSafeArea(.all)
      //            }
      //            .navigationViewStyle(.stack)
      PhonePlayerRepresentable()
        .tabItem {
          Label("Player", systemImage: "play.circle")
        }
      PhoneTopListRepresentable()
        .tabItem {
          Label("Playlists", systemImage: "list.star")
        }
      SettingsRepresentable()
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
        .ignoresSafeArea(.all)
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
