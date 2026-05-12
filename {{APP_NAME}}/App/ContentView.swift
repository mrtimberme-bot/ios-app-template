import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SettingsView()
                .tabItem {
                    Label("Instellingen", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
