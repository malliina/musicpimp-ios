import AVFoundation
import Foundation

class Players {
  static let sharedInstance = Players()
  let log = LoggerFactory.shared.pimp(Players.self)
  let suggestAtMostEvery = 15.minutes
  private var lastLocalSuggestion: DispatchTime? = nil
  private var lastRemoteSuggestion: DispatchTime? = nil

  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var settings: PimpSettings { PimpSettings.sharedInstance }

  let audioPortTypes = [
    AVAudioSession.Port.bluetoothHFP,
    AVAudioSession.Port.bluetoothA2DP,
    AVAudioSession.Port.carAudio,
    AVAudioSession.Port.headphones,
    AVAudioSession.Port.airPlay,
  ]

  func fromEndpoint(_ e: Endpoint) -> PlayerType {
    return switch e.serverType {
    case .musicPimp: PimpPlayer(e: e)
    case .cloud: PimpPlayer(e: e)
    default: LocalPlayer.sharedInstance
    }
  }

  /// Shows a playback device selection dialog to the user if suitable conditions are met.
  ///
  /// Asks whether the user wants to start listening on:
  /// - this device, if connected to headphones or bluetooth
  /// - the server, if connected to neither headphones nor bluetooth
  ///
  func playerChangeSuggestionIfNecessary() -> ChangePlayerSuggestion? {
    let isLocal = playerManager.playerChanged.isLocal
    let localOutputs = describeLocalOutput()
    let now = DispatchTime.now()
    let suggestLocal =
      localOutputs.count > 0 && !isLocal
      && Util.hasTimePassed(time: suggestAtMostEvery, now: now, since: lastLocalSuggestion)
    let suggestRemote =
      localOutputs.count == 0 && isLocal
      && Util.hasTimePassed(time: suggestAtMostEvery, now: now, since: lastRemoteSuggestion)
    if suggestLocal {
      lastLocalSuggestion = now
      return suggestion(
        to: Endpoint.Local, suggestedName: localOutputs[0], isHandoverOptional: false)
    }
    if suggestRemote {
      let to = settings.activeLibrary()
      if to.id != Endpoint.Local.id {
        lastRemoteSuggestion = now
        return suggestion(to: to, suggestedName: to.name, isHandoverOptional: true)
      }
    }
    return nil
  }

  private func suggestion(to: Endpoint, suggestedName: String, isHandoverOptional: Bool)
    -> ChangePlayerSuggestion
  {
    let player = settings.activePlayer()
    return ChangePlayerSuggestion(
      to: to, title: "Listening on \(player.name)", message: "Change to \(suggestedName)?",
      handover: isHandoverOptional
        ? "Change to \(suggestedName) with handover" : "Change to \(suggestedName)",
      changeNoHandover: isHandoverOptional ? "Change to \(suggestedName)" : nil,
      cancel: "Continue on \(player.name)")
  }

  func changePlayer(to: Endpoint) async {
    await pauseCurrent()
    await playerManager.use(endpoint: to)
  }

  func performHandover(to: Endpoint) async {
    let currentState = playerManager.playerChanged.current()
    await pauseCurrent()
    await playerManager.use(endpoint: to) { p in let _ = await p.handover(state: currentState) }
  }

  func pauseCurrent() async {
    if let error = await playerManager.playerChanged.pause() {
      self.log.warn("Unable to pause player: \(error)")
    }
  }

  func describeLocalOutput() -> [String] {
    return AVAudioSession.sharedInstance().currentRoute.outputs.flatMapOpt { (desc) -> String? in
      return switch desc.portType {
      case AVAudioSession.Port.bluetoothHFP: "Bluetooth"
      case AVAudioSession.Port.bluetoothA2DP: "Bluetooth"
      case AVAudioSession.Port.carAudio: "Car Audio"
      case AVAudioSession.Port.headphones: "Headphones"
      case AVAudioSession.Port.airPlay: "Air Play"
      default: nil
      }
    }
  }
}
