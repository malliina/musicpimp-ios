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
            topList(entries: entries, vm: popularsVM) { popular in
              "\(popular.playbackCount) plays"
            }
          }
        }
      case .recent:
        topView(vm: recentsVM) { entries in
          if entries.isEmpty {
            fullSizeText("No recent tracks.")
          } else {
            topList(entries: entries, vm: recentsVM) { recent in
              formatter.string(from: recent.timestamp)
            }
          }
        }
      }
      PlaybackFooter(vm: PlaybackVM.shared)
    }
    .background(colors.background)
  }
  
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
  
  func topList<T>(entries: [T], vm: TopData<T>, subRight: @escaping (T) -> String) -> some View where T: TopEntry {
    List {
      ForEach(entries, id: \.entry.idStr) { recent in
        Button {
          Task {
            await controls.play(recent.entry)
          }
        } label: {
          ThreeLabelRow(label: recent.entry.title, subLeft: recent.entry.artist, subRight: subRight(recent), track: recent.entry)
        }
      }
      .listRowBackground(colors.background)
      if vm.hasMore {
        ProgressView()
          .id(entries.last?.entry.idStr ?? "id") // Otherwise it shows only once?
          .frame(maxWidth: .infinity)
          .listRowSeparator(.hidden)
          .listRowBackground(colors.background)
          .task {
            await vm.loadBatch()
          }
      }
    }.listStyle(.plain)
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
  class PopularPreview: TopData<PopularEntry> {
    override func fetch(from: Int) async throws -> [PopularEntry] {
      [
        PopularEntry(track: PreviewLibrary.track1, playbackCount: 4),
        PopularEntry(track: PreviewLibrary.track2, playbackCount: 3)
      ]
    }
  }
  class RecentPreview: TopData<RecentEntry> {
    
  }
 
  static var preview: some View {
    TopListsInternal(popularsVM: PopularPreview(), recentsVM: RecentPreview())
  }
}
