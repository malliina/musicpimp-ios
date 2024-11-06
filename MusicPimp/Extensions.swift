import SwiftUI

extension View {
  var controls: Playbacks { PlaybackControls.shared }
  
  func iapAlert(isPresented: Binding<Bool>, action: @escaping () -> Void) -> some View {
    self.alert(IAPConstants.Title, isPresented: isPresented, actions: {
      Button {
        action()
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
  
  func musicConfirmationDialog(isPresented: Binding<Bool>, track: Track) -> some View {
    self.confirmationDialog("Actions", isPresented: isPresented) {
      Button {
        Task {
          await controls.play(track)
        }
      } label: {
        Text("Play")
      }
      Button {
        Task {
          await controls.add(track)
        }
      } label: {
        Text("Add")
      }
      Button {
        Task {
          await controls.download(track)
        }
      } label: {
        Text("Download")
      }
    }
  }
}

extension ObservableObject {
  var libraryManager: LibraryManager { LibraryManager.sharedInstance }
  var playerManager: PlayerManager { PlayerManager.sharedInstance }
  var library: LibraryType { libraryManager.libraryUpdated }
  var player: PlayerType { playerManager.playerChanged }
}
