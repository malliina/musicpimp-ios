import SwiftUI

struct LibraryList: View {
  @StateObject var vm: LibraryVM
  
  init(id: FolderID?) {
    _vm = StateObject(wrappedValue: LibraryVM(id: id))
  }
  
  var body: some View {
    LibraryListInternal<LibraryVM, DownloadUpdater>(vm: vm, downloads: DownloadUpdater.instance)
  }
}

struct LibraryListInternal<T, D>: View where T: LibraryVMLike, D: DownloaderLike {
  private let log = LoggerFactory.shared.view(LibraryListInternal<LibraryVM, DownloadUpdater>.self)
  @ObservedObject var vm: T
  @ObservedObject var downloads: D
  @ObservedObject var premium = PremiumState.shared
  @State private var iapLinkActive = false
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    contentView()
      .background(colors.background)
      .task {
        switch vm.appearAction {
        case .Reload:
          await vm.load()
        case .Dismiss:
          dismiss()
        case .Noop:
          ()
        }
      }
      .task(id: vm.searchText) {
        let term = vm.searchText
        await vm.search(term: term)
      }
  }
  
  @ViewBuilder
  func contentView() -> some View {
    switch vm.folder {
    case .Idle:
      fullSizeText("")
    case .Loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .Loaded(let folder):
      let title = folder.folder.title
      ZStack {
        // Hack to navigate programmatically to the IAP page in an .alert action
        NavigationLink(destination: IAPRepresentable(), isActive: $iapLinkActive) {
          EmptyView()
        }
        folderView(folder: folder)
          .navigationTitle(title.isEmpty ? "MUSICPIMP" : title)
          .searchable(text: $vm.searchText, prompt: "Search track or artist")
      }
    case .Err(let error):
      fullSizeText("Error. \(error)")
    }
  }
  
  @ViewBuilder
  private func folderView(folder: MusicFolder) -> some View {
    if let search = vm.searchResult.value() {
      if search.tracks.isEmpty {
        fullSizeText("No results for '\(search.term)'.")
      } else {
        nonEmptyBody(title: "Results for '\(search.term)'", tracks: search.tracks, folders: [])
      }
    } else {
      if folder.isEmpty {
        let title = folder.folder.title
        let text =
          if title.isEmpty {
            if vm.isLocalLibrary {
              "The music library is empty. To get started, download and install the MusicPimp server from www.musicpimp.org, then add it as a music source under Settings."
            } else {
              "The music library is empty."
            }
          } else {
            "No tracks in folder \(title)."
          }
        fullSizeText(text)
      } else {
        VStack {
          nonEmptyBody(folder: folder)
          PlaybackFooter(vm: PlaybackVM.shared)
        }
      }
    }
  }
  
  private func fullSizeText(_ text: String) -> some View {
    Text(text)
      .padding(.horizontal, 12)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  func nonEmptyBody(folder: MusicFolder) -> some View {
    let title = folder.folder.title
    return nonEmptyBody(title: title.isEmpty ? "MUSICPIMP" : title, tracks: folder.tracks, folders: folder.folders)
  }
  
  func nonEmptyBody(title: String, tracks: [Track], folders: [Folder]) -> some View {
    List {
      ForEach(folders, id: \.idStr) { item in
        NavigationLink {
          LibraryList(id: item.id)
        } label: {
          FolderItem(vm: vm, folder: item)
            .swipeActions {
              Button {
                Task {
                  await vm.play(item)
                }
              } label: {
                Text("Play")
              }
              Button {
                Task {
                  await vm.add(item)
                }
              } label: {
                Text("Add")
              }
            }
        }
      }
      .listRowBackground(colors.background)
      ForEach(tracks, id: \.idStr) { item in
        Button {
          Task {
            await vm.play(item)
          }
        } label: {
          TrackItem(vm: vm, track: item, progress: downloads.trackProgress[item.id])
        }.swipeActions {
          Button {
            Task {
              await vm.play(item)
            }
          } label: {
            Text("Play")
          }
          Button {
            Task {
              await vm.add(item)
            }
          } label: {
            Text("Add")
          }
        }
      }
      .listRowBackground(colors.background)
    }
    .listStyle(.plain)
    .navigationBarTitleDisplayMode(.inline)
    .alert(IAPConstants.Title, isPresented: $premium.isPremiumSuggestion, actions: {
      Button {
        iapLinkActive = true
      } label: {
        Text(IAPConstants.OkText)
      }
      Button {
        // cancel
      } label: {
        Text(IAPConstants.CancelText)
      }

    }, message: {
      Text(IAPConstants.Message)
    })
  }
}

struct FolderItem<T>: View where T: LibraryVMLike {
  let vm: T
  let folder: Folder
  
  var body: some View {
    HStack {
      Text(folder.title)
        .font(.title2)
        .foregroundColor(.primary)
    }
  }
}

struct TrackItem<T>: View where T: LibraryVMLike {
  let vm: T
  let track: Track
  let progress: ProgressLike?
  var progressValue: Float? {
    progress?.progress
  }
  
  @State private var isAction = false
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(track.title)
          .font(.title2)
          .foregroundColor(.primary)
          .padding(.top, 2)
        ProgressView(value: progressValue ?? 0.0)
          .progressViewStyle(.linear)
          .opacity(progressValue == nil ? 0.0 : 1.0)
      }
      Spacer()
      Button {
        isAction = true
      } label: {
        Image(systemName: "ellipsis")
          .tint(.gray)
      }.confirmationDialog("Actions", isPresented: $isAction) {
        Button {
          Task {
            await vm.play(track)
          }
        } label: {
          Text("Play")
        }
        Button {
          Task {
            await vm.add(track)
          }
        } label: {
          Text("Add")
        }
        Button {
          Task {
            await vm.download(track)
          }
        } label: {
          Text("Download")
        }
      }
    }
  }
}

struct LibraryListPreviews: PreviewProvider {
  class PreviewDownloads: DownloaderLike {
    struct PreviewProgress: ProgressLike {
      var progress: Float
    }
    var trackProgress: [TrackID : any ProgressLike] {
      [PreviewLibrary.track1.id : PreviewProgress(progress: 0.3)]
    }
  }
  static var previews: some View {
    ForEach(["iPhone 13 mini", "iPad Pro (11-inch) (4th generation)"], id: \.self) { deviceName in
      LibraryListInternal(vm: PreviewLibrary(), downloads: PreviewDownloads())
        .preferredColorScheme(.dark)
        .previewDevice(PreviewDevice(rawValue: deviceName))
        .previewDisplayName(deviceName)
    }
  }
}
