import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if !model.hasLoaded {
                ZStack {
                    StopitTheme.background.ignoresSafeArea()
                    ProgressView()
                        .accessibilityLabel("loading")
                }
            } else if model.settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .foregroundStyle(StopitTheme.primary)
        .background(StopitTheme.background)
        .alert(
            "couldn’t save",
            isPresented: Binding(
                get: { model.presentedError != nil },
                set: { if !$0 { model.presentedError = nil } }
            )
        ) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(model.presentedError ?? "please try again.")
        }
    }
}

private struct MainTabView: View {
    @State private var showingSettings = false

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            .accessibilityLabel("settings")
                        }
                    }
            }
            .tabItem { Label("today", systemImage: "circle") }

            NavigationStack {
                InsightsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            .accessibilityLabel("settings")
                        }
                    }
            }
            .tabItem { Label("insights", systemImage: "chart.xyaxis.line") }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
        }
    }
}
