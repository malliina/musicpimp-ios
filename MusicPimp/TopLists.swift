import SwiftUI

enum TopChoice {
  case popular, recent
}

struct TopLists: View {
  var body: some View {
    TopListsInternal(popularsVM: PopularData.shared, recentsVM: RecentData.shared)
  }
}

struct TopListsInternal: View {
  @State private var segment = TopChoice.popular
  @State private var iapLinkActive = false
  
  @ObservedObject var popularsVM: TopData<PopularEntry>
  @ObservedObject var recentsVM: TopData<RecentEntry>
  @ObservedObject var premium = PremiumState.shared
  
  let formatter = makeFormatter()
  var controls: Playbacks { PlaybackControls.shared }
  
  var body: some View {
    VStack {
      Picker("Segment", selection: $segment) {
        Text("Popular").tag(TopChoice.popular)
        Text("Recent").tag(TopChoice.recent)
      }
      .pickerStyle(.segmented)
      switch segment {
      case .popular:
        topView(vm: popularsVM) { entries in
          if entries.isEmpty {
            fullSizeText("No popular tracks.")
          } else {
            populars(entries: entries)
          }
        }
      case .recent:
        topView(vm: recentsVM) { entries in
          if entries.isEmpty {
            fullSizeText("No recent tracks.")
          } else {
            recents(entries: entries)
          }
        }
      }
      PlaybackFooter(vm: PlaybackVM.shared)
    }
    .background(colors.background)
  }
  
  @ViewBuilder
  func topView<R, A>(vm: TopData<R>, @ViewBuilder dataView: ([R]) -> A) -> some View where A: View {
    topData(outcome: vm.results) { r in
      dataView(r)
    }.task {
      switch vm.appearAction {
      case .Reload:
        await vm.load()
      default:
        ()
      }
    }
  }
  
  @ViewBuilder
  func topData<R, A>(outcome: Outcome<R>, @ViewBuilder dataView: (R) -> A) -> some View where A: View {
    switch outcome {
    case .Idle:
      fullSizeText("")
    case .Loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .Loaded(let r):
      ZStack {
        // Hack to navigate programmatically to the IAP page in an .alert action
        NavigationLink(destination: IAPRepresentable(), isActive: $iapLinkActive) {
          EmptyView()
        }
        dataView(r)
          .iapAlert(isPresented: $premium.isPremiumSuggestion) {
            iapLinkActive = true
          }
      }
    case .Err(let error):
      fullSizeText("Error. \(error)")
    }
  }
  
  func populars(entries: [PopularEntry]) -> some View {
    List {
      ForEach(entries, id: \.track.id) { popular in
        Button {
          Task {
            await controls.play(popular.track)
          }
        } label: {
          ThreeLabelRow(label: popular.track.title, subLeft: popular.track.artist, subRight: "\(popular.playbackCount) plays", track: popular.track)
        }
      }
      .listRowBackground(colors.background)
      loadMoreProgress(id: entries.last?.track.idStr ?? "id", vm: popularsVM)
    }.listStyle(.plain)
  }
  
  func recents(entries: [RecentEntry]) -> some View {
    List {
      ForEach(entries, id: \.track.id) { recent in
        Button {
          Task {
            await controls.play(recent.track)
          }
        } label: {
          ThreeLabelRow(label: recent.track.title, subLeft: recent.track.artist, subRight: formatter.string(from: recent.timestamp), track: recent.track)
        }
      }
      .listRowBackground(colors.background)
      loadMoreProgress(id: entries.last?.track.idStr ?? "id", vm: recentsVM)
    }.listStyle(.plain)
  }
  
  @ViewBuilder
  private func loadMoreProgress<T>(id: String, vm: TopData<T>) -> some View {
    if vm.hasMore {
      ProgressView()
        .id(id) // Otherwise it shows only once?
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(colors.background)
        .task {
          await vm.loadBatch()
        }
    }
  }
  
  static func makeFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    return formatter
  }
}

struct TopListsPreviews: PimpPreviewProvider, PreviewProvider {
  static let ps = [
    PopularEntry(track: PreviewLibrary.track1, playbackCount: 4),
    PopularEntry(track: PreviewLibrary.track2, playbackCount: 3)
  ]
  class PopularPreview: TopData<PopularEntry> {
    override func fetch(from: Int) async throws -> [PopularEntry] {
      await TopListsPreviews.ps
    }
  }
  class RecentPreview: TopData<RecentEntry> {
    
  }
 
  static var preview: some View {
    TopListsInternal(popularsVM: PopularPreview(), recentsVM: RecentPreview())
  }
}
