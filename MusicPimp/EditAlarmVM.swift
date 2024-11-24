class EditAlarmVM: ObservableObject {
  let log = LoggerFactory.shared.view(EditAlarmVM.self)
  let alarm: Alarm?
  let player: PlayerType
  
  @Published var track: Track?
  @Published var date: Date = Date.now
  @Published var weekDays: [WeekDaySelection]
  var enabledDays: [Day] {
    weekDays.filter { selection in
      selection.isSelected
    }.map { $0.day }
  }
  @Published var isPlaying: Bool = false
  private var cancellables: Set<Task<(), Never>> = []
  
  var edited: Alarm? {
    if let track = track {
      let time = ClockTime(date: date)
      let alarmTime = AlarmTime(hour: time.hour, minute: time.minute, days: enabledDays)
      return Alarm(id: alarm?.id, track: track, when: alarmTime, enabled: alarm?.enabled ?? true)
    } else {
      return nil
    }
  }
  
  init(alarm: Alarm?, player: PlayerType) {
    self.alarm = alarm
    self.player = player
    self.track = alarm?.track
    let clockTime = alarm?.when.time ?? ClockTime(hour: 8, minute: 0)
    let components = clockTime.dateComponents(Date.now)
    if let initialDate = (components as NSDateComponents).date {
      date = initialDate
    }
    let enabledDays = alarm?.when.days ?? Day.allCases
    weekDays = Day.allCases.map { day in
      WeekDaySelection(day: day, isSelected: enabledDays.contains(day))
    }
  }
  
  func playOrPause(track: Track) async {
    if isPlaying {
      let _ = await player.pause()
    } else {
      let _ = await player.resetAndPlay(tracks: [track])
    }
  }
  
  func open() async {
    let _ = await player.open()
    let task = Task {
      for await playState in player.stateEvent.removeDuplicates().nonNilValues() {
        await update(state: playState)
      }
    }
    cancellables = [task]
  }
  
  func close() {
    cancellables.forEach { task in
      task.cancel()
    }
    cancellables = []
  }
  
  @MainActor private func update(state: PlaybackState) {
    self.isPlaying = state == .Playing
  }
}
