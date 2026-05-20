import AppKit
import SwiftUI
import HazakuraLLMManagerCore

@main
struct HazakuraLLMManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = ServerController()

    var body: some Scene {
        WindowGroup("Hazakura Lantern", id: "main") {
            ContentView(controller: controller)
                .frame(minWidth: 860, minHeight: 680)
        }
        .commands {
            CommandMenu("Server") {
                Button("Start") {
                    controller.start()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!controller.canStart)

                Button("Stop") {
                    controller.stop()
                }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!controller.canStop)

                Button("Restart") {
                    controller.restart()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!controller.canRestart)
            }
        }

        MenuBarExtra {
            MenuBarControlView(controller: controller)
        } label: {
            Label("Lantern", systemImage: menuBarSystemImage)
        }
    }

    private var menuBarSystemImage: String {
        switch controller.status {
        case .running:
            "lightbulb.fill"
        case .starting, .stopping, .restarting:
            "lightbulb"
        case .error:
            "exclamationmark.triangle.fill"
        case .stopped:
            "lightbulb"
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
