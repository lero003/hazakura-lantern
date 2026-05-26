import AppKit
import SwiftUI
import HazakuraLLMManagerCore

private enum AppModel {
    static let serverController = ServerController()
}

@main
struct HazakuraLLMManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller: ServerController
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.system.rawValue

    init() {
        let controller = AppModel.serverController
        _controller = StateObject(wrappedValue: controller)
        appDelegate.serverController = controller
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .system
    }

    var body: some Scene {
        mainWindow

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

    @SceneBuilder
    private var mainWindow: some Scene {
        Window(localized("Hazakura Lantern"), id: "main") {
            ContentView(controller: controller)
                .frame(minWidth: 860, minHeight: 680)
                .environment(\.locale, appLanguage.locale)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(localized("Open Window")) {
                    NotificationCenter.default.post(name: .hazakuraShowMainWindow, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

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
        case .starting, .loading, .stopping, .restarting:
            "lightbulb"
        case .error:
            "exclamationmark.triangle.fill"
        case .stopped:
            "lightbulb"
        }
    }
}

extension Notification.Name {
    static let hazakuraShowMainWindow = Notification.Name("dev.hazakura.llmmanager.showMainWindow")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var serverController: ServerController? = AppModel.serverController
    private var isWaitingForTerminationReply = false
    private var mainWindow: NSWindow?
    private var showMainWindowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        showMainWindowObserver = NotificationCenter.default.addObserver(
            forName: .hazakuraShowMainWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showMainWindow()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.showMainWindowIfNeeded()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isWaitingForTerminationReply else {
            return .terminateLater
        }

        guard serverController?.stopForApplicationTermination(completion: { [weak self, weak sender] in
            self?.isWaitingForTerminationReply = false
            sender?.reply(toApplicationShouldTerminate: true)
        }) == true else {
            return .terminateNow
        }

        isWaitingForTerminationReply = true
        return .terminateLater
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }

    deinit {
        if let showMainWindowObserver {
            NotificationCenter.default.removeObserver(showMainWindowObserver)
        }
    }

    private func showMainWindowIfNeeded() {
        guard visibleMainWindow == nil else { return }
        showMainWindow()
    }

    private func showMainWindow() {
        if let window = visibleMainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard let serverController else { return }

        let window = mainWindow ?? makeMainWindow(controller: serverController)
        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var visibleMainWindow: NSWindow? {
        NSApp.windows.first { window in
            window.canBecomeMain
                && window.isVisible
                && !window.isMiniaturized
                && window.frame.width >= 860
                && window.frame.height >= 680
        }
    }

    private func makeMainWindow(controller: ServerController) -> NSWindow {
        let language = AppLanguage(
            rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey)
                ?? AppLanguage.system.rawValue
        ) ?? .system
        let title = String(
            localized: "Hazakura Lantern",
            bundle: .module,
            locale: language.locale
        )
        let rootView = ContentView(controller: controller)
            .frame(minWidth: 860, minHeight: 680)
            .environment(\.locale, language.locale)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentView = NSHostingView(rootView: rootView)
        window.setFrameAutosaveName("HazakuraLanternMainWindow")
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }
}
