import SwiftUI
import Combine

struct VolumeView: View {
  let log = LoggerFactory.shared.view(VolumeView.self)
  @ObservedObject var vm: VolumeVM
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    HStack {
      faButton(name: "fa-volume-down") {
        Task {
          await vm.decrement()
        }
      }
      Slider(
        value: $vm.volume,
        in: 0...vm.maximum,
        onEditingChanged: { editing in
          vm.isEditing = editing
        }
      )
      faButton(name: "fa-volume-up") {
        Task {
          await vm.increment()
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 12)
    .background(colors.background)
    .navigationTitle("SET VOLUME")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          dismiss()
        }
      }
    }
  }
}

struct VolumePreviews: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    VolumeView(vm: VolumeVM.shared)
  }
}

class VolumeVM: ObservableObject {
  let log = LoggerFactory.shared.system(VolumeVM.self)
  static let shared = VolumeVM()
  private let q = DispatchQueue(label: "VolumeVM")
  static var playerStatic: PlayerType { PlayerManager.sharedInstance.playerChanged }
  var player: PlayerType { VolumeVM.playerStatic }
  @Published var volume: Float = Float(playerStatic.current().volume.value)
  @Published var isEditing: Bool = false
  let maximum: Float = 100.0
  private var cancellables: Set<Task<(), Never>> = []

  var updates: Published<VolumeValue?>.Publisher {
    player.volumeEvent
  }
  var userChanges: Publishers.Throttle<Published<Float>.Publisher, DispatchQueue> {
    $volume.throttle(for: 0.2, scheduler: DispatchQueue.main, latest: true)
  }
  
  init() {
    let task1 = Task {
      for await vol in updates.removeDuplicates().values {
        if let vol = vol {
          await update(to: vol)
        }
      }
    }
    let task2 = Task {
      for await change in userChanges.values {
        await onEdited(to: change)
      }
    }
    cancellables = [task1, task2]
  }
  
  func onEdited(to: Float) async {
    if isEditing {
      let _ = await player.volume(VolumeValue(volume: Int(to)))
    }
  }
  
  func increment() async {
    Task {
//      await updatePlayer(to: min(volume + 10, maximum))
    }
  }
  
  func decrement() async {
    Task {
//      await updatePlayer(to: max(volume - 10, 0))
    }
  }
  
  @MainActor func update(to: VolumeValue) {
    volume = Float(to.value)
  }
}
