import SwiftUI

struct AlarmsView: View {
  @ObservedObject var vm: AlarmsVM
  
  @State var isAddNew: Bool = false
  
  var body: some View {
    List {
      Text("MusicPimp supports scheduled playback of music.")
        .listRowBackground(colors.background)
      Picker("Player", selection: $vm.selectedId) {
        if vm.selectedId == "" {
          Text("Select").tag("")
        }
        ForEach(vm.savedEndpoints) { p in
          Text(p.name).tag(p.id)
        }
      }.listRowBackground(colors.background)
      Spacer()
        .frame(height: 24)
        .listRowBackground(colors.background)
      Text("Receive a notification when scheduled playback starts, so that you can easily silence it.")
        .listRowBackground(colors.background)
      Toggle("Notifications", isOn: $vm.isNotificationsEnabled)
        .listRowBackground(colors.background)
      if let feedback = vm.notificationsFeedback {
        Text(feedback)
          .foregroundStyle(colors.subtitles)
          .listRowBackground(colors.background)
      }
      Spacer()
        .frame(height: 24)
        .listRowBackground(colors.background)
      Text(vm.alarms.isEmpty ? "No scheduled tracks." : "Scheduled tracks")
        .listRowBackground(colors.background)
      ForEach(vm.alarms, id: \.idOrEmpty) { a in
        NavigationLink(destination: EditAlarmView(alarm: a, vm: vm)) {
          ScheduledAlarm(alarm: a, vm: vm)
        }
      }.listRowBackground(colors.background)
    }
    .onChange(of: vm.isNotificationsEnabled) { isEnabled in
      Task {
        await vm.toggle(notificationsEnabled: isEnabled)
      }
    }
    .listStyle(.plain)
    .background(colors.background)
    .onChange(of: vm.selectedId) { newValue in
      Task {
        await vm.select(id: newValue)
      }
    }
    .navigationTitle("Alarms")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isAddNew = true
        } label: {
          Image(systemName: "plus")
        }
      }
    }
    .sheet(isPresented: $isAddNew) {
      NavigationView {
        EditAlarmView(alarm: nil, vm: vm)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button("Cancel") {
                isAddNew = false
              }
            }
          }
      }
    }
  }
}

struct ScheduledAlarm: View {
  let log = LoggerFactory.shared.view(ScheduledAlarm.self)
  
  let alarm: Alarm
  let vm: AlarmsVM
  
  @State var isAlarmEnabled: Bool
  
  init(alarm: Alarm, vm: AlarmsVM) {
    self.alarm = alarm
    self.vm = vm
    isAlarmEnabled = alarm.enabled
  }
  
  var body: some View {
    Toggle(isOn: $isAlarmEnabled) {
      VStack(alignment: .leading, spacing: 6) {
        Text(alarm.describe)
        subtitle(Day.describeDays(Set(alarm.when.days)))
      }
    }
    .onChange(of: isAlarmEnabled) { newValue in
      log.info("Toggled alarm to \(newValue)")
      Task {
        let mutable = MutableAlarm(alarm)
        mutable.enabled = newValue
        if let updated = mutable.toImmutable() {
          await vm.save(a: updated)
        }
      }
    }
  }
}

struct AlarmsPreview: PimpPreviewProvider, PreviewProvider {
  static let previewAlarms = [
    Alarm(id: AlarmID(id: "id"), track: PreviewLibrary.track1, when: AlarmTime(hour: 14, minute: 32, days: [Day.Fri]), enabled: true)
  ]
  class PreviewAlarmSource: AlarmsSource {
    @Published var p: Endpoint? = PreviewSource.e1
    
    var player: Published<Endpoint?>.Publisher {
      $p
    }
    func alarms(endpoint: Endpoint) async -> [Alarm] {
      []
    }
  }
  static var preview: some View {
    AlarmsView(vm: AlarmsVM(source: PreviewSource(), alarmsSource: PreviewAlarmSource(), initialAlarms: previewAlarms))
  }
}
