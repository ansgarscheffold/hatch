import Foundation

struct LocalizedStrings {
    private static var isGerman: Bool {
        switch AppSettings.shared.appLanguage {
        case .system:
            guard let preferredLanguage = Locale.preferredLanguages.first else { return false }
            return preferredLanguage.hasPrefix("de")
        case .german:
            return true
        case .english:
            return false
        }
    }
    
    // Navigation
    static var overview: String { isGerman ? "Übersicht" : "Overview" }
    static var keys: String { isGerman ? "Schlüssel" : "Keys" }
    static var activeConnections: String { isGerman ? "Aktive Verbindungen" : "Active Connections" }
    static var recent: String { isGerman ? "Letzte Verbindungen" : "Recent" }
    
    // Server Cards
    static var hostIP: String { isGerman ? "Host/IP" : "Host/IP" }
    static var user: String { isGerman ? "Benutzer" : "User" }
    static var port: String { isGerman ? "Port" : "Port" }
    static var lastUsed: String { isGerman ? "Zuletzt verwendet" : "Last used" }
    static var neverUsed: String { isGerman ? "Nie verwendet" : "Never used" }
    static var active: String { isGerman ? "aktiv" : "active" }
    static var connected: String { isGerman ? "Verbunden" : "Connected" }
    static var connect: String { isGerman ? "Verbinden" : "Connect" }
    static var tools: String { isGerman ? "Werkzeuge" : "Tools" }
    static var ping: String { isGerman ? "Ping" : "Ping" }
    static var traceroute: String { isGerman ? "Traceroute" : "Traceroute" }
    static var noPingData: String { isGerman ? "Keine Ping-Daten verfügbar." : "No ping data available." }
    static var noTracerouteData: String { isGerman ? "Keine Traceroute-Daten verfügbar." : "No traceroute data available." }
    static var columnSequence: String { isGerman ? "Nr." : "Seq" }
    static var columnHop: String { "Hop" }
    static var columnHost: String { isGerman ? "Host" : "Host" }
    static var columnTimeMs: String { isGerman ? "Zeit (ms)" : "Time (ms)" }
    static var columnHostnameOrIP: String { isGerman ? "Hostname / IP" : "Hostname / IP" }
    static var toolsRawOutput: String { isGerman ? "Ausgabe" : "Output" }

    static var serverNotFound: String { isGerman ? "Server nicht gefunden" : "Server not found" }
    static var backToOverview: String { isGerman ? "Zurück zur Übersicht" : "Back to Overview" }
    static var keyCreatedLabel: String { isGerman ? "Erstellt" : "Created" }
    static var pickerNone: String { isGerman ? "Keine" : "None" }
    
    // Server Overview
    static var yourServers: String { isGerman ? "Ihre Server" : "Your Servers" }
    static var noServersYet: String { isGerman ? "Noch keine Server" : "No Servers Yet" }
    static var addFirstServer: String { isGerman ? "Fügen Sie Ihren ersten Server hinzu, um mit SSH-Verbindungen zu beginnen" : "Add your first server to get started with SSH connections" }
    static var addServer: String { isGerman ? "Server hinzufügen" : "Add Server" }
    
    // Modals
    static var editServer: String { isGerman ? "Server bearbeiten" : "Edit Server" }
    static var deleteServer: String { isGerman ? "Server löschen" : "Delete Server" }
    static var deleteAllServers: String { isGerman ? "Alle Server löschen" : "Delete All Servers" }
    static var deleteAllServersDescription: String {
        isGerman
            ? "Alle gespeicherten Server und aktiven Verbindungen werden entfernt. Fortfahren?"
            : "All saved servers and active connections will be removed. Continue?"
    }
    
    // UI / View
    static var viewSettings: String { isGerman ? "Ansicht" : "View" }
    static var showStatusBar: String { isGerman ? "Statusleiste anzeigen" : "Show status bar" }
    static var showSidebar: String { isGerman ? "Seitenleiste anzeigen" : "Show sidebar" }
    static var deleteKey: String { isGerman ? "Schlüssel löschen" : "Delete Key" }
    static func deleteConfirmation(_ name: String) -> String {
        isGerman ? "Möchten Sie '\(name)' wirklich löschen?" : "Are you sure you want to delete '\(name)'?"
    }
    static var deleteWarning: String { isGerman ? "Diese Aktion kann nicht rückgängig gemacht werden." : "This action cannot be undone." }
    static var cancel: String { isGerman ? "Abbrechen" : "Cancel" }
    static var close: String { isGerman ? "Schließen" : "Close" }
    static var delete: String { isGerman ? "Löschen" : "Delete" }
    static var saveOnly: String { isGerman ? "Nur speichern" : "Save Only" }
    static var save: String { isGerman ? "Speichern" : "Save" }
    static var saveAndConnect: String { isGerman ? "Speichern & Verbinden" : "Save & Connect" }
    
    // Server Details Form
    static var serverDetails: String { isGerman ? "Server-Details" : "Server Details" }
    static var nameOptional: String { isGerman ? "Name (optional)" : "Name (optional)" }
    static var authentication: String { isGerman ? "Authentifizierung" : "Authentication" }
    static var username: String { isGerman ? "Benutzername" : "Username" }
    static var usePassword: String { isGerman ? "Passwort verwenden" : "Use Password" }
    static var password: String { isGerman ? "Passwort" : "Password" }
    static var privateKey: String { isGerman ? "Privater Schlüssel" : "Private Key" }
    static var choose: String { isGerman ? "Auswählen" : "Choose" }
    static var noKeySelected: String { isGerman ? "Kein Schlüssel ausgewählt" : "No Key Selected" }
    
    // Terminal
    static func startTerminalPrompt(_ name: String) -> String {
        isGerman ? "Terminal für '\(name)' starten?" : "Start terminal for '\(name)'?"
    }
    static var startTerminal: String { isGerman ? "Terminal starten" : "Start Terminal" }
    static func connectionLost(_ name: String) -> String {
        isGerman ? "Verbindung zu '\(name)' verloren" : "Connection lost for '\(name)'"
    }
    static var reconnect: String { isGerman ? "Erneut verbinden" : "Reconnect" }
    static var disconnect: String { isGerman ? "Trennen" : "Disconnect" }
    static func connectingTo(_ name: String) -> String {
        isGerman ? "Verbinde mit '\(name)'..." : "Connecting to '\(name)'..."
    }
    static var connectionFailedTitle: String { isGerman ? "Verbindung fehlgeschlagen" : "Connection failed" }
    static var connectionFailedHint: String {
        isGerman
            ? "Bitte Host, Port, Zugangsdaten und Netzwerkverbindung prüfen."
            : "Please check host, port, credentials, and network connectivity."
    }
    static func connectionFailedDetail(host: String, port: Int) -> String {
        if isGerman {
            return "Konnte keine Verbindung zu \(host):\(port) herstellen; bitte Host, Port, Erreichbarkeit und Firewall prüfen."
        } else {
            return "Could not connect to \(host):\(port); please check host, port, reachability, and firewall."
        }
    }

    /// Verbindungs-Status und Fehlertexte (werden u. a. in Fehler-UI und internen Meldungen genutzt).
    static var statusReadyToConnect: String { isGerman ? "Bereit zum Verbinden" : "Ready to connect" }
    static var statusConnecting: String { isGerman ? "Verbinde …" : "Connecting..." }
    static var statusFailedToCreateShell: String { isGerman ? "Shell konnte nicht erstellt werden" : "Failed to create shell" }
    static var connectionErrorShellInstance: String {
        isGerman
            ? "SSH-Shell-Instanz konnte nicht erstellt werden."
            : "Failed to create SSH shell instance."
    }
    static var statusAuthenticationFailed: String { isGerman ? "Authentifizierung fehlgeschlagen" : "Authentication failed" }
    static var connectionErrorKeyFileUnreadable: String {
        isGerman
            ? "SSH-Schlüsseldatei konnte nicht gelesen werden; bitte Pfad und Berechtigungen prüfen."
            : "Could not read SSH key file; please check path and permissions."
    }
    static var connectionErrorAuthFailed: String {
        isGerman
            ? "Authentifizierung fehlgeschlagen; bitte Benutzername, Passwort oder SSH-Schlüssel prüfen."
            : "Authentication failed; please check username, password, or SSH key."
    }
    static var statusConnected: String { isGerman ? "Verbunden" : "Connected" }
    static var statusConnectedOpeningTerminal: String {
        isGerman ? "Verbunden – Terminal wird geöffnet …" : "Connected - Opening terminal..."
    }
    static var statusDisconnected: String { isGerman ? "Getrennt" : "Disconnected" }
    static var terminalNoActiveSSH: String { isGerman ? "Keine aktive SSH-Verbindung" : "No active SSH connection" }
    static var osDetecting: String { isGerman ? "Wird erkannt …" : "Detecting..." }
    static var osUnknown: String { isGerman ? "Unbekannt" : "Unknown" }
    static var statusInteractiveShellClosed: String {
        isGerman ? "Interaktive Shell beendet" : "Interactive shell closed"
    }

    static func statusBarServerCount(_ count: Int) -> String {
        isGerman ? "Server: \(count)" : "Servers: \(count)"
    }
    static func statusBarActiveCount(_ count: Int) -> String {
        isGerman ? "Aktiv: \(count)" : "Active: \(count)"
    }

    static func toolFailedToStartPing(_ detail: String) -> String {
        isGerman ? "Ping konnte nicht gestartet werden: \(detail)" : "Failed to start ping: \(detail)"
    }
    static func toolFailedToStartTraceroute(_ detail: String) -> String {
        isGerman ? "Traceroute konnte nicht gestartet werden: \(detail)" : "Failed to start traceroute: \(detail)"
    }

    static func keyGenerationFailedExitCode(_ code: Int32) -> String {
        isGerman
            ? "SSH-Schlüssel konnte nicht erzeugt werden (Fehlercode \(code))."
            : "Failed to generate SSH key. Error code: \(code)"
    }
    static func keyGenerationFailed(_ detail: String) -> String {
        isGerman
            ? "SSH-Schlüssel konnte nicht erzeugt werden: \(detail)"
            : "Failed to generate SSH key: \(detail)"
    }
    
    // Welcome Screen
    static var sshTerminal: String { isGerman ? "SSH Terminal" : "SSH Terminal" }
    static var connectToRemote: String { isGerman ? "Mit einem Remote-Server über SSH verbinden" : "Connect to a remote server using SSH" }
    static var features: String { isGerman ? "Funktionen:" : "Features:" }
    static var secureConnections: String { isGerman ? "Sichere SSH-Verbindungen" : "Secure SSH connections" }
    static var interactiveTerminal: String { isGerman ? "Interaktives Terminal" : "Interactive terminal" }
    static var passwordAndKeyAuth: String { isGerman ? "Passwort- und Schlüssel-Authentifizierung" : "Password and key authentication" }
    
    // Keys
    static var noKeys: String { isGerman ? "Keine Schlüssel" : "No keys" }
    static var savedKeysWillAppear: String { isGerman ? "Gespeicherte Schlüssel werden hier angezeigt. Beginnen Sie mit dem Hinzufügen eines neuen Schlüssels." : "Saved keys will appear here. Start by adding a new key." }
    static var newKey: String { isGerman ? "Neuer Schlüssel" : "New Key" }
    static var editKey: String { isGerman ? "Schlüssel bearbeiten" : "Edit Key" }
    static var keyLabel: String { isGerman ? "Name" : "Label" }
    static var publicKeyOptional: String { isGerman ? "Öffentlicher Schlüssel (optional)" : "Public Key (optional)" }
    static var publicKeyAutoGenerated: String { isGerman ? "Öffentlicher Schlüssel (wird automatisch generiert)" : "Public Key (auto-generated)" }
    static var generate: String { isGerman ? "Generieren" : "Generate" }
    static var importKey: String { isGerman ? "Importieren" : "Import" }
    static var keyType: String { isGerman ? "Schlüsseltyp" : "Key Type" }
    static var privateKeysEncrypted: String { isGerman ? "Private Schlüssel werden immer verschlüsselt gespeichert." : "Private keys are always stored in encrypted form." }
    static var publicKeyInstallHint: String { isGerman ? "Wichtig: Kopieren Sie den öffentlichen Schlüssel und fügen Sie ihn auf dem Server in ~/.ssh/authorized_keys ein." : "Important: Copy the public key and add it to ~/.ssh/authorized_keys on the server." }
    static var copy: String { isGerman ? "Kopieren" : "Copy" }
    static var extractPublicKey: String { isGerman ? "Aus privatem Schlüssel extrahieren" : "Extract from private key" }
    static var keyName: String { isGerman ? "Schlüsselname" : "Key Name" }
    
    // Settings
    static var settings: String { isGerman ? "Einstellungen" : "Settings" }
    static var preferences: String { isGerman ? "Einstellungen" : "Preferences" }

    // Menu Bar
    static var noServersInMenu: String { isGerman ? "Keine Server" : "No servers" }
    static func quitApplication(_ appName: String) -> String {
        isGerman ? "\(appName) beenden" : "Quit \(appName)"
    }
    static var terminalTheme: String { isGerman ? "Terminal-Theme" : "Terminal Theme" }
    static var themeStandard: String { isGerman ? "Standard" : "Standard" }
    static var themeLight: String { isGerman ? "Hell" : "Light" }
    static var themeDark: String { isGerman ? "Dunkel" : "Dark" }
    
    // Settings Categories
    static var terminalSettings: String { isGerman ? "Terminal" : "Terminal" }
    static var terminalSettingsDescription: String { isGerman ? "Passen Sie das Aussehen und Verhalten des Terminals an" : "Customize the appearance and behavior of the terminal" }
    static var sessionSettings: String { isGerman ? "Sitzungen" : "Sessions" }
    static var sessionSettingsDescription: String { isGerman ? "Konfigurieren Sie das Verhalten von SSH-Sitzungen" : "Configure SSH session behavior" }
    static var connectionSettings: String { isGerman ? "Verbindung" : "Connection" }
    static var connectionSettingsDescription: String { isGerman ? "Konfigurieren Sie Standardwerte für SSH-Verbindungen" : "Configure default values for SSH connections" }
    static var generalSettings: String { isGerman ? "Allgemein" : "General" }
    static var generalSettingsDescription: String { isGerman ? "Allgemeine App-Einstellungen und Verhalten" : "General app settings and behavior" }
    static var preferencesDescription: String { isGerman ? "Verwalten Sie Ihre App-Einstellungen" : "Manage your app settings" }
    
    // Terminal Settings
    static var fontSize: String { isGerman ? "Schriftgröße" : "Font Size" }
    static var terminalThemeDescription: String { isGerman ? "Wählen Sie das Farbschema für das Terminal" : "Choose the color scheme for the terminal" }
    static var fontSizeDescription: String { isGerman ? "Stellen Sie die Schriftgröße des Terminals ein" : "Set the font size of the terminal" }
    static var fontFamily: String { isGerman ? "Schriftfamilie" : "Font Family" }
    static var cursorStyle: String { isGerman ? "Cursor-Stil" : "Cursor Style" }
    static var scrollBufferSize: String { isGerman ? "Scroll-Puffer Größe" : "Scroll Buffer Size" }
    static var keepDisplayActive: String { isGerman ? "Bildschirm aktiv halten" : "Keep Display Active" }
    static var fontFamilyDescription: String { isGerman ? "Wählen Sie die Schriftart für das Terminal" : "Choose the font family for the terminal" }
    static var cursorStyleDescription: String { isGerman ? "Wählen Sie den Cursor-Stil" : "Choose the cursor style" }
    static var scrollBufferDescription: String { isGerman ? "Anzahl der Zeilen im Scroll-Puffer" : "Number of lines in scroll buffer" }
    static var keepDisplayDescription: String { isGerman ? "Terminal-Bildschirm auch bei Inaktivität aktiv halten" : "Keep terminal display active even when inactive" }

    // Cursor Styles
    static var blinkBar: String { isGerman ? "Blinkender Balken" : "Blink Bar" }
    static var blinkBlock: String { isGerman ? "Blinkender Block" : "Blink Block" }
    static var steadyBlock: String { isGerman ? "Fester Block" : "Steady Block" }
    static var blinkUnderline: String { isGerman ? "Blinkende Unterstreichung" : "Blink Underline" }
    static var steadyUnderline: String { isGerman ? "Feste Unterstreichung" : "Steady Underline" }
    static var steadyBar: String { isGerman ? "Fester Balken" : "Steady Bar" }

    // System Font
    static var systemFont: String { isGerman ? "System" : "System" }

    // Session Settings
    static var detectOperatingSystem: String { isGerman ? "Betriebssystem erkennen" : "Detect Operating System" }
    static var keepSessionsAlive: String { isGerman ? "Sitzungen am Leben erhalten" : "Keep Sessions Alive" }
    static var detectOSDescription: String { isGerman ? "Zeigt das erkannte Betriebssystem in der Terminal-Toolbar" : "Shows detected operating system in terminal toolbar" }
    static var keepAliveDescription: String { isGerman ? "Verhindert automatische Trennung inaktiver SSH-Sitzungen" : "Prevents automatic disconnection of inactive SSH sessions" }

    // Connection Settings
    static var connectionTimeout: String { isGerman ? "Verbindungs-Timeout" : "Connection Timeout" }
    static var connectionTimeoutDescription: String { isGerman ? "Maximale Wartezeit für Verbindungsversuche" : "Maximum wait time for connection attempts" }
    static var defaultPort: String { isGerman ? "Standard-Port" : "Default Port" }
    static var defaultPortDescription: String { isGerman ? "Standard-Port für neue Server-Verbindungen" : "Default port for new server connections" }
    
    // General Settings
    static var launchAtLogin: String { isGerman ? "Beim Anmelden starten" : "Launch at Login" }
    static var launchAtLoginDescription: String { isGerman ? "App automatisch beim Systemstart öffnen" : "Automatically open app when you log in" }
    static var showNotifications: String { isGerman ? "Benachrichtigungen anzeigen" : "Show Notifications" }
    static var showNotificationsDescription: String { isGerman ? "Benachrichtigungen für Verbindungsstatus anzeigen" : "Show notifications for connection status" }

    // Language
    static var language: String { isGerman ? "Sprache" : "Language" }
    static var languageDescription: String { isGerman ? "App-Sprache auswählen" : "Select app language" }
    static var languageSystem: String { isGerman ? "Systemsprache" : "System Language" }
    static var languageGerman: String { "Deutsch" }
    static var languageEnglish: String { "English" }

    // About
    static func aboutApp(_ name: String) -> String {
        isGerman ? "Über \(name)" : "About \(name)"
    }

    static var aboutCredits: String {
        if isGerman {
            return """
Hatch ist ein schlankes SSH-Tool für macOS: Server und Verbindungen verwaltest du an einem Ort, SSH-Schlüssel legst du an oder importierst sie, und im integrierten Terminal passt du Themes, Schriftarten und Cursor-Stile an – alles ohne überladene Oberfläche.
"""
        } else {
            return """
Hatch is a streamlined SSH tool for macOS: manage servers and connections in one place, create or import SSH keys, and use the built-in terminal with customizable themes, fonts, and cursor styles—without a cluttered interface.
"""
        }
    }
}

