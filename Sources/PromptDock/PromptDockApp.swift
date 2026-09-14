import SwiftUI

@main
struct PromptDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PromptStore()

    var body: some Scene {
        WindowGroup("PromptDock") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1120, idealWidth: 1280, minHeight: 720, idealHeight: 820)
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("PromptDock", systemImage: "text.badge.plus") {
            MenuBarPromptView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
