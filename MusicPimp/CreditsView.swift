import Foundation
import SwiftUI

struct CreditsView: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("Developed by Michael Skogberg.")
                .foregroundColor(colors.titles)
            Spacer()
            Text("Design by Alisa.")
                .padding(.bottom, 24)
                .foregroundColor(colors.titles)
            if let bundleMeta = Bundle.main.infoDictionary,
               let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
               let buildId = bundleMeta["CFBundleVersion"] as? String {
                Text("Version \(appVersion) build \(buildId)")
                    .font(.system(size: 14))
                    .foregroundColor(colors.subtitles)
//                Spacer(minLength: 20)
            }
            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .background(colors.background)
        .navigationTitle("CREDITS")
    }
}

struct CreditsPreview: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
