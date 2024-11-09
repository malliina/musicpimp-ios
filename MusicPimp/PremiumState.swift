class PremiumState: ObservableObject {
  static let shared = PremiumState()
  
  @Published var isPremiumSuggestion: Bool = false
  
  func limitChecked<T>(_ code: () async -> T) async -> T? {
    if Limiter.sharedInstance.isWithinLimit() {
      return await code()
    } else {
      await suggestPremium()
      return nil
    }
  }
  
  @MainActor
  private func suggestPremium() {
    isPremiumSuggestion = true
  }
}
