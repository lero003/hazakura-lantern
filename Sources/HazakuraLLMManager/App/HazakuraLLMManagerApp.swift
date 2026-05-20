import AppKit
import SwiftUI
import HazakuraLLMManagerCore

@main
struct HazakuraLLMManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = ServerController()
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    var body: some Scene {
        WindowGroup(localized("Hazakura Lantern"), id: "main") {
            ContentView(controller: controller)
                .frame(minWidth: 860, minHeight: 680)
                .environment(\.locale, appLanguage.locale)
        }
        .commands {
            CommandMenu(localized("Server")) {
                Button(localized("Start")) {
                    controller.start()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!controller.canStart)

                Button(localized("Stop")) {
                    controller.stop()
                }
                .keyboardShortcut(".", modifiers: [.command])
                .disabled(!controller.canStop)

                Button(localized("Restart")) {
                    controller.restart()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!controller.canRestart)
            }
        }

        Settings {
            SettingsView()
                .environment(\.locale, appLanguage.locale)
        }

        MenuBarExtra {
            MenuBarControlView(controller: controller)
                .environment(\.locale, appLanguage.locale)
        } label: {
            Label(localized("Lantern"), systemImage: menuBarSystemImage)
        }
    }

    private func localized(_ key: String) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .module,
            locale: appLanguage.locale
        )
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
