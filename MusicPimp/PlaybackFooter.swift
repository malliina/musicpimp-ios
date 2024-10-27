import SwiftUI

class PlaybackVM: ObservableObject {
  static let shared = PlaybackVM()
  
  let log = LoggerFactory.shared.system(PlaybackVM.self)
  var premium: PremiumState { PremiumState.shared }
  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var player: PlayerType { playerManager.playerChanged }
  
  @Published var isPlaying = false
  
  init() {
    Task {
      let events = playerManager.$playerChanged.flatMap { player in
        player.stateEvent
      }
      for await playState in events.removeDuplicates().nonNilValues() {
        await update(playing: playState == .Playing)
      }
    }
  }
  
  @MainActor
  private func update(playing: Bool) {
    isPlaying = playing
  }
  
  func onPrev() async {
    _ = await premium.limitChecked {
      await self.player.prev()
    }
  }

  func onPlayPause() async {
    await playOrPause()
  }

  func onNext() async {
    _ = await premium.limitChecked {
      await self.player.next()
    }
  }
  
  private func playOrPause() async {
    if player.current().isPlaying {
      _ = await self.player.pause()
    } else {
      _ = await premium.limitChecked {
        await self.player.play()
      }
    }
  }
}

struct PlaybackFooter: View {
  @ObservedObject var vm: PlaybackVM
  
  var body: some View {
    HStack {
      Spacer()
      faButton(name: "fa-step-backward") {
        await vm.onPrev()
      }
      Spacer()
      faButton(name: vm.isPlaying ? "fa-pause" : "fa-play") {
        await vm.onPlayPause()
      }
      Spacer()
      faButton(name: "fa-step-forward") {
        await vm.onNext()
      }
      Spacer()
    }
    .padding(.vertical, 12)
  }
  
  @ViewBuilder
  func faButton(name: String, action: @escaping () async -> ()) -> some View {
    Button {
      Task {
        await action()
      }
    } label: {
      Text(String.fontAwesomeIconStringForIconIdentifier(name))
        .font(Font(UIFont(awesomeFontOfSize: 24)))
    }
  }
}

struct PlaybackFooterPreviews: PimpPreviewProvider {
  static var preview: some View {
    PlaybackFooter(vm: PlaybackVM.shared)
  }
}
