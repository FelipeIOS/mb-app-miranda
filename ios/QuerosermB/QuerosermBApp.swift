import SwiftUI

@main
struct QuerosermBApp: App {
    var body: some Scene {
        WindowGroup {
            ExchangeListView()
                .preferredColorScheme(.dark)
        }
    }
}
