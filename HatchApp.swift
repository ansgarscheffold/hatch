import SwiftUI
import AppKit

@main
struct HatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared
    @StateObject private var viewModel = AppViewModel()
    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    setupMenu()
                }
                .onChange(of: settings.appLanguage) { _ in
                    setupMenu()
                }
        }
        .defaultSize(width: 940, height: 720)
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
        MenuBarExtra(HatchApp.bundleDisplayName, systemImage: HatchApp.menuBarSystemImageName) {
            MenuBarExtraRootView()
                .environmentObject(viewModel)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(LocalizedStrings.aboutApp(appName)) {
                    openAboutPanel()
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button(LocalizedStrings.preferences + "...") {
                    HatchApp.openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button(LocalizedStrings.addServer) {
                    viewModel.selectedNavigationItem = .overview
                    viewModel.showAddServerSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Button(LocalizedStrings.newKey) {
                    viewModel.selectedNavigationItem = .keys
                    viewModel.showNewKeySheet = true
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }
    }
    
    private func setupMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        let language = resolvedMenuLanguage()
        localizeTopLevelMenus(in: mainMenu, language: language)
        localizeMenuItems(in: mainMenu, language: language)
    }

    @MainActor
    static func openSettingsWindow() {
        DispatchQueue.main.async {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = LocalizedStrings.preferences
            window.setContentSize(NSSize(width: 700, height: 550))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor
    private func openAboutPanel() {
        var options: [NSApplication.AboutPanelOptionKey: Any] = [:]
        options[.applicationName] = appName

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            if let build = build, !build.isEmpty {
                options[.applicationVersion] = "\(version) (\(build))"
            } else {
                options[.applicationVersion] = version
            }
        }

        // Use attributed string for credits with minimal formatting
        let creditsText = LocalizedStrings.aboutCredits
        let attributedCredits = NSAttributedString(string: creditsText)
        options[.credits] = attributedCredits

        if let icon = HatchApp.makeAppIcon() {
            options[.applicationIcon] = icon
        }

        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func resolvedMenuLanguage() -> AppLanguage {
        switch settings.appLanguage {
        case .system:
            return Locale.preferredLanguages.first?.hasPrefix("de") == true ? .german : .english
        default:
            return settings.appLanguage
        }
    }

    private func localizeTopLevelMenus(in menu: NSMenu, language: AppLanguage) {
        let germanTitles: [String: String] = [
            "File": "Ablage",
            "Edit": "Bearbeiten",
            "View": "Darstellung",
            "Window": "Fenster",
            "Help": "Hilfe"
        ]

        let englishTitles: [String: String] = [
            "Ablage": "File",
            "Bearbeiten": "Edit",
            "Darstellung": "View",
            "Fenster": "Window",
            "Hilfe": "Help"
        ]

        for item in menu.items {
            if language == .german, let newTitle = germanTitles[item.title] {
                item.title = newTitle
            } else if language == .english, let newTitle = englishTitles[item.title] {
                item.title = newTitle
            }
        }
    }

    private func localizeMenuItems(in menu: NSMenu, language: AppLanguage) {
        for item in menu.items {
            if let action = item.action, let translated = translatedTitle(for: action, language: language) {
                item.title = translated
            } else {
                applyCustomMenuTitles(to: item, language: language)
                if language == .german, item.title == "Services" {
                    item.title = "Dienste"
                } else if language == .english, item.title == "Dienste" {
                    item.title = "Services"
                }
            }

            if let submenu = item.submenu {
                localizeMenuItems(in: submenu, language: language)
            }
        }
    }

    private func translatedTitle(for action: Selector, language: AppLanguage) -> String? {
        switch action {
        case #selector(NSApplication.orderFrontStandardAboutPanel(_:)):
            return LocalizedStrings.aboutApp(appName)
        case #selector(NSApplication.hide(_:)):
            return language == .german ? "\(appName) ausblenden" : "Hide \(appName)"
        case #selector(NSApplication.hideOtherApplications(_:)):
            return language == .german ? "Andere ausblenden" : "Hide Others"
        case #selector(NSApplication.unhideAllApplications(_:)):
            return language == .german ? "Alle einblenden" : "Show All"
        case #selector(NSApplication.terminate(_:)):
            return language == .german ? "\(appName) beenden" : "Quit \(appName)"
        case #selector(NSWindow.performClose(_:)):
            return language == .german ? "Fenster schließen" : "Close Window"
        case #selector(NSWindow.performMiniaturize(_:)):
            return language == .german ? "Im Dock ablegen" : "Minimize"
        case #selector(NSWindow.performZoom(_:)):
            return language == .german ? "Zoomen" : "Zoom"
        case #selector(NSApplication.arrangeInFront(_:)):
            return language == .german ? "Alle nach vorne bringen" : "Bring All to Front"
        case #selector(NSWindow.toggleFullScreen(_:)):
            return language == .german ? "Vollbildmodus" : "Enter Full Screen"
        case #selector(UndoManager.undo):
            return language == .german ? "Widerrufen" : "Undo"
        case #selector(UndoManager.redo):
            return language == .german ? "Wiederholen" : "Redo"
        case #selector(NSText.cut(_:)):
            return language == .german ? "Ausschneiden" : "Cut"
        case #selector(NSText.copy(_:)):
            return language == .german ? "Kopieren" : "Copy"
        case #selector(NSText.paste(_:)):
            return language == .german ? "Einfügen" : "Paste"
        case #selector(NSText.selectAll(_:)):
            return language == .german ? "Alles auswählen" : "Select All"
        default:
            return nil
        }
    }

    private func applyCustomMenuTitles(to item: NSMenuItem, language: AppLanguage) {
        let customPairs: [(english: String, german: String)] = [
            ("Add Server", "Server hinzufügen"),
            ("New Key", "Neuer Schlüssel"),
            ("Preferences...", "Einstellungen...")
        ]

        for pair in customPairs {
            if item.title == pair.english || item.title == pair.german {
                item.title = language == .german ? pair.german : pair.english
                break
            }
        }
    }

    private var appName: String {
        Self.bundleDisplayName
    }

    static var bundleDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Hatch"
    }

    /// Gleiche Form wie in der Menüleiste (Template); Dock nutzt `makeAppIcon()` mit Farbe.
    static let menuBarSystemImageName = "door.left.hand.open"

    static func makeAppIcon() -> NSImage? {
        if let dock = makeColoredDockIconFromMenuBarSymbol() {
            return dock
        }

        guard let base = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil) else {
            return nil
        }
        let config = NSImage.SymbolConfiguration(pointSize: 128, weight: .regular)
        let configured = base.withSymbolConfiguration(config) ?? base
        configured.isTemplate = false
        configured.size = NSSize(width: 128, height: 128)
        return configured
    }

    /// Dock-Icon: dasselbe SF Symbol wie die Menüleiste, mit Markenfarben (Orange + Schiefer).
    private static func makeColoredDockIconFromMenuBarSymbol() -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: menuBarSystemImageName, accessibilityDescription: "Hatch") else {
            return nil
        }

        let pixelSize: CGFloat = 512
        let canvas = NSSize(width: pixelSize, height: pixelSize)
        let pointSize = pixelSize * 0.52

        let orange = NSColor(srgbRed: 244 / 255, green: 154 / 255, blue: 67 / 255, alpha: 1)
        let slate = NSColor(srgbRed: 92 / 255, green: 119 / 255, blue: 130 / 255, alpha: 1)

        let weightCfg = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        let paletteCfg = NSImage.SymbolConfiguration(paletteColors: [orange, slate])
        let combined = weightCfg.applying(paletteCfg)
        guard let configured = symbol.withSymbolConfiguration(combined) else { return nil }

        let image = NSImage(size: canvas, flipped: false) { bounds in
            NSColor.clear.set()
            NSBezierPath(rect: bounds).fill()

            let repSize = configured.size
            let maxW = bounds.width * 0.78
            let maxH = bounds.height * 0.78
            let scale = min(maxW / max(repSize.width, 1), maxH / max(repSize.height, 1))
            let dw = repSize.width * scale
            let dh = repSize.height * scale
            let dx = bounds.midX - dw / 2
            let dy = bounds.midY - dh / 2
            let drawRect = NSRect(x: dx, y: dy, width: dw, height: dh)

            NSGraphicsContext.current?.imageInterpolation = .high
            configured.draw(
                in: drawRect,
                from: NSRect(origin: .zero, size: repSize),
                operation: .sourceOver,
                fraction: 1.0
            )
            return true
        }
        image.isTemplate = false
        return image
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app appears in front and is activatable when launched from terminal
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Set custom app icon
        if let icon = HatchApp.makeAppIcon() {
            NSApp.applicationIconImage = icon
        }
    }
}







