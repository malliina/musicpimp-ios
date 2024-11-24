import SwiftUI

struct EditAlarmView: View {
  let log = LoggerFactory.shared.view(EditAlarmView.self)
  
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var vm: AlarmsVM
  @StateObject var editVm: EditAlarmVM
  @FocusState private var searchFocused: Bool
  
  init(alarm: Alarm?, vm: AlarmsVM) {
    _editVm = StateObject(wrappedValue: EditAlarmVM(alarm: alarm, player: vm.player))
    self.vm = vm
  }
  
  var isAddNew: Bool {
    editVm.alarm == nil
  }
  
  var body: some View {
    contentView()
      .searchable(text: $vm.searchText, prompt: "Search track")
      .task(id: vm.searchText) {
        let term = vm.searchText
        await vm.search(term: term)
      }
      .padding()
      .background(colors.background)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            if let edited = editVm.edited {
              Task {
                await vm.save(a: edited)
                dismiss()
              }
            }
          }.disabled(editVm.edited == nil)
        }
      }
  }
  
  @ViewBuilder
  private func contentView() -> some View {
    if let search = vm.searchResult.value() {
      AlarmSearchView(tracks: search.tracks) { track in
        editVm.track = track
        vm.searchText = ""
      }
    } else {
      ScrollView {
        HStack {
          Text("Track")
          Spacer()
          Text(editVm.track?.title ?? "No track")
        }
        .foregroundStyle(colors.titles)
        DatePicker("Time", selection: $editVm.date, displayedComponents: [.hourAndMinute])
          .datePickerStyle(.wheel)
          .colorScheme(.dark)
        if let track = editVm.track {
          NavigationLink(destination: WeekDaysSelector(weekDays: $editVm.weekDays)) {
            HStack {
              Text("Repeat")
              Spacer()
              Text(Day.describeDays(Set(editVm.enabledDays)))
            }
          }
          Spacer()
            .frame(height: 24)
          Button(editVm.isPlaying ? "Pause" : "Play now") {
            Task {
              await editVm.playOrPause(track: track)
            }
          }.buttonStyle(.borderedProminent)
        }
        Spacer()
          .frame(height: 48)
        if !isAddNew {
          Button(role: .destructive) {
            if let alarm = editVm.alarm, let id = alarm.id {
              Task {
                await vm.remove(id: id)
                dismiss()
              }
            }
          } label: {
            Text("Delete")
          }.buttonStyle(.borderedProminent)
        }
      }
      .task {
        await editVm.open()
      }
      .onDisappear {
        editVm.close()
      }
    }
  }
}

// Subview so that dismissSearch works
struct AlarmSearchView: View {
  @Environment(\.dismissSearch) private var dismissSearch
  
  let tracks: [Track]
  let onSelected: (Track) -> Void
  
  var body: some View {
    List {
      ForEach(tracks, id: \.idStr) { track in
        Button {
          onSelected(track)
          dismissSearch()
        } label: {
          ThreeLabelRow(label: track.title, subLeft: track.artist, subRight: track.album, track: nil)
        }
        .listRowBackground(colors.background)
      }
    }.listStyle(.plain)
  }
}

struct EditAlarmPreview: PimpPreviewProvider, PreviewProvider {
  static var preview: some View {
    EditAlarmView(alarm: nil, vm: AlarmsVM.shared)
  }
}
