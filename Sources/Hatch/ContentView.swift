import SwiftUI
import Foundation
import Combine
import NSRemoteShell
import XTerminalUI
import GRDB
import CryptoKit
import AppKit
import Security

/// Zusätzlicher Innenabstand für Toolbar-Inhalte (einheitliche Toolbar / neuere macOS-Versionen).
private enum MainWindowToolbarInsets {
    static let horizontal: CGFloat = 12
    /// Terminal-Titelzeile: gleicher Abstand links und rechts zum Toolbar-Rand.
    static let terminalTitleHorizontal: CGFloat = 28
    static let terminalTitleVertical: CGFloat = 4
}

/// Eine Zeile: Servername links, Verbindungszeile und optional OS rechts daneben (Toolbar-Höhe wie übrige Items).
private struct TerminalToolbarTitleRow: View {
    let displayName: String
    let connectionLine: String
    let operatingSystem: String?

    private static let metaFont = Font.subheadline.weight(.regular)

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(displayName)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 10) {
                Text(connectionLine)
                    .font(Self.metaFont)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let os = operatingSystem, !os.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "cube")
                            .font(Self.metaFont)
                        Text(os)
                            .font(Self.metaFont)
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
            }
        }
        .padding(.vertical, MainWindowToolbarInsets.terminalTitleVertical)
        .padding(.horizontal, MainWindowToolbarInsets.terminalTitleHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Models

enum TerminalTheme: String, CaseIterable {
    case standard = "standard"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .standard:
            return LocalizedStrings.themeStandard
        case .light:
            return LocalizedStrings.themeLight
        case .dark:
            return LocalizedStrings.themeDark
        }
    }

    var backgroundColor: NSColor {
        switch self {
        case .standard:
            return NSColor.windowBackgroundColor
        case .light:
            return NSColor.white
        case .dark:
            return NSColor.black
        }
    }

    var textColor: String {
        switch self {
        case .standard:
            let bgColor = NSColor.windowBackgroundColor
            // Convert to RGB colorspace before accessing components
            if let rgbColor = bgColor.usingColorSpace(.deviceRGB) {
                let brightness = (rgbColor.redComponent * 299 + rgbColor.greenComponent * 587 + rgbColor.blueComponent * 114) / 1000
                return brightness > 0.5 ? "#000000" : "#FFFFFF"
            } else {
                // Fallback: assume light background
                return "#000000"
            }
        case .light:
            return "#000000"
        case .dark:
            return "#FFFFFF"
        }
    }
}

enum TerminalFontFamily: String, CaseIterable {
    case menlo = "Menlo"
    case cascadiaCode = "Cascadia Code"
    case courier = "Courier"
    case firaCode = "Fira Code"
    case jetbrainsMono = "JetBrains Mono"
    case sourceCodePro = "Source Code Pro"
    case ubuntuMono = "Ubuntu Mono"

    var displayName: String {
        switch self {
        case .menlo:
            return "Menlo"
        case .cascadiaCode:
            return "Cascadia Code"
        case .courier:
            return "Courier"
        case .firaCode:
            return "Fira Code"
        case .jetbrainsMono:
            return "JetBrains Mono"
        case .sourceCodePro:
            return "Source Code Pro"
        case .ubuntuMono:
            return "Ubuntu Mono"
        }
    }

    var cssFontFamily: String {
        switch self {
        case .menlo:
            return "'Menlo', monospace"
        case .cascadiaCode:
            return "'Cascadia Code', monospace"
        case .courier:
            return "'Courier New', monospace"
        case .firaCode:
            return "'Fira Code', monospace"
        case .jetbrainsMono:
            return "'JetBrains Mono', monospace"
        case .sourceCodePro:
            return "'Source Code Pro', monospace"
        case .ubuntuMono:
            return "'Ubuntu Mono', monospace"
        }
    }
}

enum TerminalCursorStyle: String, CaseIterable {
    case blinkBar = "blink-bar"
    case blinkBlock = "blink-block"
    case steadyBlock = "steady-block"
    case blinkUnderline = "blink-underline"
    case steadyUnderline = "steady-underline"
    case steadyBar = "steady-bar"

    var displayName: String {
        switch self {
        case .blinkBar:
            return LocalizedStrings.blinkBar
        case .blinkBlock:
            return LocalizedStrings.blinkBlock
        case .steadyBlock:
            return LocalizedStrings.steadyBlock
        case .blinkUnderline:
            return LocalizedStrings.blinkUnderline
        case .steadyUnderline:
            return LocalizedStrings.steadyUnderline
        case .steadyBar:
            return LocalizedStrings.steadyBar
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case german
    case english

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return LocalizedStrings.languageSystem
        case .german: return LocalizedStrings.languageGerman
        case .english: return LocalizedStrings.languageEnglish
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Terminal Settings
    @Published var terminalTheme: TerminalTheme {
        didSet {
            UserDefaults.standard.set(terminalTheme.rawValue, forKey: "terminalTheme")
        }
    }
    
    @Published var terminalFontSize: Int {
        didSet {
            UserDefaults.standard.set(terminalFontSize, forKey: "terminalFontSize")
        }
    }
    
    // Connection Settings
    @Published var connectionTimeout: Int {
        didSet {
            UserDefaults.standard.set(connectionTimeout, forKey: "connectionTimeout")
        }
    }
    
    @Published var defaultPort: Int {
        didSet {
            UserDefaults.standard.set(defaultPort, forKey: "defaultPort")
        }
    }
    
    // Terminal Settings
    @Published var terminalFontFamily: TerminalFontFamily {
        didSet {
            UserDefaults.standard.set(terminalFontFamily.rawValue, forKey: "terminalFontFamily")
        }
    }

    @Published var terminalCursorStyle: TerminalCursorStyle {
        didSet {
            UserDefaults.standard.set(terminalCursorStyle.rawValue, forKey: "terminalCursorStyle")
        }
    }

    @Published var terminalScrollBufferSize: Int {
        didSet {
            UserDefaults.standard.set(terminalScrollBufferSize, forKey: "terminalScrollBufferSize")
        }
    }

    @Published var terminalKeepDisplayActive: Bool {
        didSet {
            UserDefaults.standard.set(terminalKeepDisplayActive, forKey: "terminalKeepDisplayActive")
        }
    }

    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
        }
    }

    // Session Settings
    @Published var detectOperatingSystem: Bool {
        didSet {
            UserDefaults.standard.set(detectOperatingSystem, forKey: "detectOperatingSystem")
        }
    }

    @Published var keepSessionsAlive: Bool {
        didSet {
            UserDefaults.standard.set(keepSessionsAlive, forKey: "keepSessionsAlive")
        }
    }

    // General Settings
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        }
    }
    
    // UI Settings
    @Published var showStatusBar: Bool {
        didSet {
            UserDefaults.standard.set(showStatusBar, forKey: "showStatusBar")
        }
    }
    
    @Published var showSidebar: Bool {
        didSet {
            UserDefaults.standard.set(showSidebar, forKey: "showSidebar")
        }
    }
    
    private init() {
        // Terminal Theme
        if let savedTheme = UserDefaults.standard.string(forKey: "terminalTheme") {
            // Migrate old theme values
            let migratedTheme: String
            switch savedTheme {
            case "auto", "system":
                migratedTheme = "standard"
            default:
                migratedTheme = savedTheme
            }
            
            if let theme = TerminalTheme(rawValue: migratedTheme) {
                self.terminalTheme = theme
                // Update stored value if migration occurred
                if migratedTheme != savedTheme {
                    UserDefaults.standard.set(migratedTheme, forKey: "terminalTheme")
                }
            } else {
                self.terminalTheme = .standard
            }
        } else {
            self.terminalTheme = .standard
        }
        
        // Terminal Font Size
        self.terminalFontSize = UserDefaults.standard.object(forKey: "terminalFontSize") as? Int ?? 12
        
        // Connection Settings
        self.connectionTimeout = UserDefaults.standard.object(forKey: "connectionTimeout") as? Int ?? 10
        self.defaultPort = UserDefaults.standard.object(forKey: "defaultPort") as? Int ?? 22
        
        // Terminal Settings
        if let savedFontFamily = UserDefaults.standard.string(forKey: "terminalFontFamily"),
           let fontFamily = TerminalFontFamily(rawValue: savedFontFamily) {
            self.terminalFontFamily = fontFamily
        } else {
            // Migration: falls früher "system-ui" gespeichert war, auf Menlo zurückfallen
            if let savedFontFamily = UserDefaults.standard.string(forKey: "terminalFontFamily"),
               savedFontFamily == "system-ui" {
                self.terminalFontFamily = .menlo
                UserDefaults.standard.set(TerminalFontFamily.menlo.rawValue, forKey: "terminalFontFamily")
            } else {
                self.terminalFontFamily = .menlo
            }
        }

        if let savedCursorStyle = UserDefaults.standard.string(forKey: "terminalCursorStyle"),
           let cursorStyle = TerminalCursorStyle(rawValue: savedCursorStyle) {
            self.terminalCursorStyle = cursorStyle
        } else {
            self.terminalCursorStyle = .blinkBlock
        }
        self.terminalScrollBufferSize = UserDefaults.standard.object(forKey: "terminalScrollBufferSize") as? Int ?? 1000
        self.terminalKeepDisplayActive = UserDefaults.standard.object(forKey: "terminalKeepDisplayActive") as? Bool ?? true

        // Language
        if let savedLang = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: savedLang) {
            self.appLanguage = lang
        } else {
            self.appLanguage = .system
        }

        // Session Settings
        self.detectOperatingSystem = UserDefaults.standard.object(forKey: "detectOperatingSystem") as? Bool ?? true
        self.keepSessionsAlive = UserDefaults.standard.object(forKey: "keepSessionsAlive") as? Bool ?? true

        // General Settings
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
        self.showNotifications = UserDefaults.standard.object(forKey: "showNotifications") as? Bool ?? true
        
        // UI Settings
        self.showStatusBar = UserDefaults.standard.object(forKey: "showStatusBar") as? Bool ?? true
        self.showSidebar = UserDefaults.standard.object(forKey: "showSidebar") as? Bool ?? true
    }
}

struct Server: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "servers"
    var id: UUID
    var name: String
    var host: String
    var port: Int = 22
    var username: String
    var password: String?
    var usePassword: Bool = true
    var privateKeyPath: String? = nil // Legacy support
    var keyId: UUID? = nil // Reference to SSHKey
    var createdAt: Date = Date()
    var lastUsed: Date?
    var operatingSystem: String? = nil

    var displayName: String {
        name.isEmpty ? host : name
    }

    var connectionString: String {
        "\(username)@\(host):\(port)"
    }

    // Database columns
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
        static let port = Column(CodingKeys.port)
        static let username = Column(CodingKeys.username)
        static let password = Column(CodingKeys.password)
        static let usePassword = Column(CodingKeys.usePassword)
        static let privateKeyPath = Column(CodingKeys.privateKeyPath)
        static let keyId = Column(CodingKeys.keyId)
        static let createdAt = Column(CodingKeys.createdAt)
        static let lastUsed = Column(CodingKeys.lastUsed)
        static let operatingSystem = Column(CodingKeys.operatingSystem)
    }

    // GRDB-specific: Custom encoding/decoding for UUID as String in database
    init(row: Row) throws {
        if let idString = row[Columns.id] as String? {
            id = UUID(uuidString: idString) ?? UUID()
        } else {
            id = UUID()
        }
        name = row[Columns.name]
        host = row[Columns.host]
        port = row[Columns.port]
        username = row[Columns.username]
        password = row[Columns.password]
        usePassword = row[Columns.usePassword]
        privateKeyPath = row[Columns.privateKeyPath]
        if let keyIdString = row[Columns.keyId] as String? {
            keyId = UUID(uuidString: keyIdString)
        } else {
            keyId = nil
        }
        createdAt = row[Columns.createdAt]
        lastUsed = row[Columns.lastUsed]
        operatingSystem = row[Columns.operatingSystem]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.name] = name
        container[Columns.host] = host
        container[Columns.port] = port
        container[Columns.username] = username
        container[Columns.password] = password
        container[Columns.usePassword] = usePassword
        container[Columns.privateKeyPath] = privateKeyPath
        container[Columns.keyId] = keyId?.uuidString
        container[Columns.createdAt] = createdAt
        container[Columns.lastUsed] = lastUsed
        container[Columns.operatingSystem] = operatingSystem
    }

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        password: String?,
        usePassword: Bool = true,
        privateKeyPath: String? = nil,
        keyId: UUID? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil,
        operatingSystem: String? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.usePassword = usePassword
        self.privateKeyPath = privateKeyPath
        self.keyId = keyId
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.operatingSystem = operatingSystem
    }
}

struct ToolsSheet: View {
    let server: Server
    let tool: String
    @Binding var output: [String]
    @Binding var isPresented: Bool
    let stopAction: () -> Void
    
    private let bottomAnchorId = "toolsSheetBottomAnchor"

    private var localizedToolTitle: String {
        let t = tool.lowercased()
        if t.contains("ping") { return LocalizedStrings.ping }
        if t.contains("trace") { return LocalizedStrings.traceroute }
        return tool.capitalized
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (ähnlicher Stil wie Add/Edit-Server-Modal)
            HStack {
                Text("\(localizedToolTitle) – \(server.displayName)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if isPing {
                            pingTable
                        } else if isTraceroute {
                            tracerouteTable
                        } else {
                            rawOutputView
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorId)
                    }
                    .padding(24)
                }
                .onAppear {
                    scheduleAutoScroll(proxy: proxy)
                }
                .onChange(of: output.count) { _ in
                    scheduleAutoScroll(proxy: proxy)
                }
                .onChange(of: pingRows.count) { _ in
                    scheduleAutoScroll(proxy: proxy)
                }
                .onChange(of: tracerouteRows.count) { _ in
                    scheduleAutoScroll(proxy: proxy)
                }
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button {
                    stopAction()
                    isPresented = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                        Text(LocalizedStrings.cancel)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 600, minHeight: 380)
    }
    
    private func scheduleAutoScroll(proxy: ScrollViewProxy) {
        guard hasContent else { return }
        DispatchQueue.main.async {
            scrollToBottom(proxy: proxy)
        }
    }
    
    private var hasContent: Bool {
        if isPing {
            return !pingRows.isEmpty
        }
        if isTraceroute {
            return !tracerouteRows.isEmpty
        }
        return !output.isEmpty
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard hasContent else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(bottomAnchorId, anchor: .bottom)
        }
    }

    // MARK: - Parsed data

    private var isPing: Bool {
        tool.lowercased().contains("ping")
    }

    private var isTraceroute: Bool {
        tool.lowercased().contains("trace")
    }

    private var pingRows: [PingRow] {
        output.compactMap { PingRow.parse(line: $0) }
    }

    private var tracerouteRows: [TracerouteRow] {
        output.compactMap { TracerouteRow.parse(line: $0) }
    }

    // MARK: - Views

    private var pingTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.ping)
                .font(.headline)

            if pingRows.isEmpty {
                Text(LocalizedStrings.noPingData)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Header
                HStack {
                    Text(LocalizedStrings.columnSequence)
                        .frame(width: 40, alignment: .leading)
                    Text(LocalizedStrings.columnHost)
                        .frame(minWidth: 160, alignment: .leading)
                    Text(LocalizedStrings.columnTimeMs)
                        .frame(width: 80, alignment: .trailing)
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Divider()

                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(pingRows) { row in
                        HStack {
                            Text(row.sequence)
                                .frame(width: 40, alignment: .leading)
                            Text(row.host)
                                .frame(minWidth: 160, alignment: .leading)
                            Text(row.timeMS)
                                .frame(width: 80, alignment: .trailing)
                            Spacer()
                        }
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .id(row.id)
                    }
                }
            }
        }
    }

    private var tracerouteTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.traceroute)
                .font(.headline)

            if tracerouteRows.isEmpty {
                Text(LocalizedStrings.noTracerouteData)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Header
                HStack {
                    Text(LocalizedStrings.columnHop)
                        .frame(width: 40, alignment: .leading)
                    Text(LocalizedStrings.columnHostnameOrIP)
                        .frame(minWidth: 280, alignment: .leading)
                    Text(LocalizedStrings.columnTimeMs)
                        .frame(minWidth: 140, alignment: .leading)
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Divider()

                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(tracerouteRows) { row in
                        HStack(alignment: .top, spacing: 4) {
                            Text(row.hop)
                                .frame(width: 40, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                if let hostname = row.hostname, !hostname.isEmpty {
                                    Text(hostname)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    Text(row.ip)
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(row.ip)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                }
                            }
                            .frame(minWidth: 280, alignment: .leading)
                            Text(row.times.map { $0 == "*" ? "*" : ($0.contains("ms") ? $0 : "\($0) ms") }.joined(separator: ", "))
                                .frame(minWidth: 140, alignment: .leading)
                            Spacer()
                        }
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .id(row.id)
                    }
                }
            }
        }
    }

    private var rawOutputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.toolsRawOutput)
                .font(.headline)
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(output.indices, id: \.self) { idx in
                    Text(output[idx])
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(idx)
                }
            }
        }
    }

    // MARK: - Row Models

    struct PingRow: Identifiable {
        let id = UUID()
        let sequence: String
        let host: String
        let timeMS: String

        static func parse(line: String) -> PingRow? {
            // Beispiel: "64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=23.456 ms"
            guard line.contains("icmp_seq") else { return nil }
            let parts = line.split(separator: " ")
            var host = ""
            var seq = ""
            var time = ""
            for part in parts {
                if part.hasPrefix("from") {
                    // next token is host
                    if let idx = parts.firstIndex(of: part), idx + 1 < parts.count {
                        host = String(parts[idx + 1]).trimmingCharacters(in: CharacterSet(charactersIn: ":"))
                    }
                }
                if part.hasPrefix("icmp_seq=") {
                    seq = String(part.dropFirst("icmp_seq=".count))
                }
            }
            if let range = line.range(of: "time=") {
                let after = line[range.upperBound...]
                if let msRange = after.range(of: " ms") {
                    time = String(after[..<msRange.lowerBound])
                }
            }
            if host.isEmpty { host = "-" }
            if seq.isEmpty { seq = "-" }
            if time.isEmpty { time = "-" }
            return PingRow(sequence: seq, host: host, timeMS: time)
        }
    }

    struct TracerouteRow: Identifiable {
        let id = UUID()
        let hop: String
        let hostname: String?  // Hostname/FQDN (z.B. "router.example.com")
        let ip: String          // IP-Adresse
        let times: [String]

        var displayHost: String {
            if let hostname = hostname, !hostname.isEmpty {
                return "\(hostname) (\(ip))"
            }
            return ip
        }

        static func parse(line: String) -> TracerouteRow? {
            // Erwartet Zeilen wie: " 1  router.example.com (192.168.0.1)  1.123 ms  1.234 ms  1.345 ms"
            // Oder: " 1  192.168.0.1 (192.168.0.1)  1.123 ms  1.234 ms  1.345 ms"
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            
            // Skip header lines
            if trimmed.hasPrefix("traceroute") || trimmed.hasPrefix("traceroute to") || trimmed.hasPrefix("Hops") {
                return nil
            }
            
            // Erste Komponente Hop-Nummer
            let components = trimmed.split(separator: " ").map { String($0) }
            guard let first = components.first, Int(first) != nil else { return nil }
            let hop = first
            var hostname: String? = nil
            var ip = ""
            var times: [String] = []

            // Verwende Regex, um Zeiten zu finden und zu extrahieren (z.B. "1.234 ms", "1.234ms", "* ms")
            let timePattern = #"(\*|[\d]+\.[\d]+|[\d]+)\s*ms"#
            let regex = try? NSRegularExpression(pattern: timePattern, options: [])
            let nsString = trimmed as NSString
            let matches = regex?.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // Sammle alle Zeit-Werte
            var timeRanges: [NSRange] = []
            if let matches = matches, !matches.isEmpty {
                for match in matches {
                    let matchString = nsString.substring(with: match.range)
                    let timeValue = matchString.replacingOccurrences(of: "ms", with: "").trimmingCharacters(in: .whitespaces)
                    if !timeValue.isEmpty {
                        times.append(timeValue)
                        timeRanges.append(match.range)
                    }
                }
            }
            
            // Entferne Zeit-Werte aus der Zeile, um den Host zu parsen
            var lineWithoutTimes = trimmed
            for range in timeRanges.sorted(by: { $0.location > $1.location }) {
                let nsRange = NSRange(location: range.location, length: range.length)
                lineWithoutTimes = (lineWithoutTimes as NSString).replacingCharacters(in: nsRange, with: "")
            }
            // Bereinige doppelte Leerzeichen
            lineWithoutTimes = lineWithoutTimes.replacingOccurrences(of: "  ", with: " ", options: [], range: nil)
            lineWithoutTimes = lineWithoutTimes.trimmingCharacters(in: .whitespaces)

            // Parse Host aus der bereinigten Zeile
            let hostComponents = lineWithoutTimes.split(separator: " ").map { String($0) }
            var i = 1 // Skip hop number
            
            // Suche nach IP in Klammern und Hostname davor
            while i < hostComponents.count {
                let c = hostComponents[i]
                
                if c.contains("(") {
                    // IP in Klammern - könnte über mehrere Tokens gehen
                    var ipParts: [String] = [c]
                    var j = i + 1
                    while j < hostComponents.count && !hostComponents[j].contains(")") {
                        ipParts.append(hostComponents[j])
                        j += 1
                    }
                    if j < hostComponents.count {
                        ipParts.append(hostComponents[j])
                    }
                    let fullIP = ipParts.joined(separator: " ")
                    let extractedIP = fullIP.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                    if !extractedIP.isEmpty {
                        ip = extractedIP
                    }
                    
                    // Prüfe, ob vor der IP ein Hostname steht
                    if i > 1 {
                        let potentialHostname = hostComponents[i - 1]
                        // Hostname sollte keine IP sein und keine Zahl
                        if !potentialHostname.contains(".") || potentialHostname.split(separator: ".").count > 2 || 
                           (potentialHostname.split(separator: ".").allSatisfy { Int($0) != nil }) == false {
                            // Prüfe, ob es wie ein Hostname aussieht (enthält Buchstaben oder hat mehr als 2 Punkte)
                            if potentialHostname.rangeOfCharacter(from: CharacterSet.letters) != nil || 
                               potentialHostname.split(separator: ".").count > 2 {
                                hostname = potentialHostname
                            }
                        }
                    }
                    i = j + 1
                    break
                } else if !c.isEmpty && c != "*" {
                    // Prüfe, ob es eine IP-Adresse ist (4 Zahlen durch Punkte getrennt)
                    let ipPattern = #"^(\d{1,3}\.){3}\d{1,3}$"#
                    let ipRegex = try? NSRegularExpression(pattern: ipPattern, options: [])
                    let isIP = ipRegex?.firstMatch(in: c, options: [], range: NSRange(location: 0, length: c.utf16.count)) != nil
                    
                    if isIP {
                        ip = c
                    } else if Double(c) == nil && hostname == nil {
                        // Potentieller Hostname (nur wenn es keine Zahl ist)
                        hostname = c
                    }
                }
                i += 1
            }

            if ip.isEmpty {
                ip = "-"
            }
            if times.isEmpty {
                times = ["-"]
            }
            return TracerouteRow(hop: hop, hostname: hostname, ip: ip, times: times)
        }
    }
}

enum AuthMethod {
    case password
    case key
}

struct SSHKey: Identifiable, Codable, Hashable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "ssh_keys"
    var id: UUID
    var name: String
    var privateKey: String // Encrypted
    var publicKey: String? // Optional, encrypted
    var createdAt: Date = Date()
    
    // Database columns
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let privateKey = Column(CodingKeys.privateKey)
        static let publicKey = Column(CodingKeys.publicKey)
        static let createdAt = Column(CodingKeys.createdAt)
    }
    
    init(row: Row) throws {
        if let idString = row[Columns.id] as String? {
            id = UUID(uuidString: idString) ?? UUID()
        } else {
            id = UUID()
        }
        name = row[Columns.name]
        privateKey = row[Columns.privateKey]
        publicKey = row[Columns.publicKey]
        createdAt = row[Columns.createdAt]
    }
    
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id.uuidString
        container[Columns.name] = name
        container[Columns.privateKey] = privateKey
        container[Columns.publicKey] = publicKey
        container[Columns.createdAt] = createdAt
    }
    
    init(id: UUID = UUID(), name: String, privateKey: String, publicKey: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.createdAt = createdAt
    }
}

enum KeyType: String, CaseIterable {
    case ed25519 = "ED25519"
    case ecdsa256 = "ECDSA256"
    case ecdsa384 = "ECDSA384"
    case ecdsa521 = "ECDSA521"
}

enum NavigationItem: Hashable {
    case overview
    case keys
    case server(Server)
}

// MARK: - View Models

class AppViewModel: ObservableObject {
    @Published var servers: [Server] = []
    @Published var keys: [SSHKey] = []
    @Published var selectedNavigationItem: NavigationItem? = .overview
    @Published var connectedServers: [UUID: ConnectionManager] = [:]
    @Published var showAddServerSheet = false
    @Published var showEditServerSheet: Server? = nil
    @Published var showDeleteConfirmation: Server? = nil
    @Published var showDeleteAllServersConfirmation = false
    @Published var showNewKeySheet = false
    @Published var showEditKeySheet: SSHKey? = nil
    @Published var showDeleteKeyConfirmation: SSHKey? = nil
    @Published var terminalHolders: [UUID: TerminalHolder] = [:]
    @Published var pendingAutoConnect: UUID? = nil

    private var dbQueue: DatabaseQueue?
    private var connectionCancellables: [UUID: AnyCancellable] = [:]
    
    /// Einmal pro App-Lebensdauer. Der Master-Key für AES-GCM liegt **ausschließlich in der Keychain** (Passwörter selbst: verschlüsselt in der DB, nicht als Keychain-Einträge).
    /// macOS: zuerst Data-Protection-Keychain; bei `errSecMissingEntitlement` (-34018, z. B. unsigniertes `swift build`) Fallback auf den klassischen Login-Schlüsselbund — weiterhin Keychain, keine Datei.
    private lazy var encryptionKey: SymmetricKey = Self.loadOrCreateMasterEncryptionKey()

    /// Alte Debug-Builds legten den Key hier ab — einmal einlesen, in die Keychain schreiben, Datei entfernen.
    private static func deprecatedMasterKeyFileURL() -> URL? {
        guard let base = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        return base.appendingPathComponent("Hatch", isDirectory: true).appendingPathComponent(".hatch_master_encryption_key")
    }

    private static func loadOrCreateMasterEncryptionKey() -> SymmetricKey {
        let keychainService = "com.hatch.app.encryption"
        let keychainAccount = "masterEncryptionKey"

        #if os(macOS)
        let legacyIdentity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        var dpIdentity: [String: Any] = legacyIdentity
        dpIdentity[kSecUseDataProtectionKeychain as String] = true
        #else
        let legacyIdentity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        let dpIdentity = legacyIdentity
        #endif

        func keyDataMatching(_ base: [String: Any]) -> Data? {
            var q = base
            q[kSecReturnData as String] = true
            q[kSecMatchLimit as String] = kSecMatchLimitOne
            var out: AnyObject?
            guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
                  let data = out as? Data,
                  data.count == 32 else { return nil }
            return data
        }

        func addKey(_ data: Data, identity: [String: Any]) -> OSStatus {
            var q = identity
            q[kSecValueData as String] = data
            q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            return SecItemAdd(q as CFDictionary, nil)
        }

        if let existing = keyDataMatching(dpIdentity) {
            return SymmetricKey(data: existing)
        }

        #if os(macOS)
        if let legacyKey = keyDataMatching(legacyIdentity) {
            SecItemDelete(dpIdentity as CFDictionary)
            let dpStatus = addKey(legacyKey, identity: dpIdentity)
            if dpStatus == errSecSuccess {
                SecItemDelete(legacyIdentity as CFDictionary)
            }
            return SymmetricKey(data: legacyKey)
        }
        #endif

        #if os(macOS)
        if let fileURL = deprecatedMasterKeyFileURL(),
           let fileData = try? Data(contentsOf: fileURL),
           fileData.count == 32 {
            SecItemDelete(dpIdentity as CFDictionary)
            SecItemDelete(legacyIdentity as CFDictionary)
            var st = addKey(fileData, identity: dpIdentity)
            if st == errSecMissingEntitlement {
                st = addKey(fileData, identity: legacyIdentity)
            }
            if st == errSecSuccess {
                try? FileManager.default.removeItem(at: fileURL)
            }
            return SymmetricKey(data: fileData)
        }
        #endif

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        SecItemDelete(dpIdentity as CFDictionary)
        #if os(macOS)
        SecItemDelete(legacyIdentity as CFDictionary)
        #endif

        var status = addKey(keyData, identity: dpIdentity)
        #if os(macOS)
        if status == errSecMissingEntitlement {
            status = addKey(keyData, identity: legacyIdentity)
            if status == errSecSuccess {
                print("Note: Data-Protection-Keychain nicht verfügbar (fehlende Entitlement); Master-Key im Login-Schlüsselbund.")
            }
        }
        #endif
        if status != errSecSuccess {
            print("Warning: Master-Key konnte nicht in der Keychain gespeichert werden: \(status)")
        }
        return newKey
    }

    init() {
        setupDatabase()
        loadServers()
        loadKeys()
    }

    private func setupDatabase() {
        do {
            // Create database path in Application Support directory
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let appDirectoryURL = appSupportURL.appendingPathComponent("Hatch", isDirectory: true)

            if !fileManager.fileExists(atPath: appDirectoryURL.path) {
                try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true)
            }

            let dbURL = appDirectoryURL.appendingPathComponent("servers.db")

            // Create SQLite database
            // Note: Sensitive data (passwords, keys) are encrypted with AES-GCM before storage
            // The database file itself is not encrypted, but all sensitive fields are encrypted
            // This approach works without additional dependencies and is secure for most use cases
            dbQueue = try DatabaseQueue(path: dbURL.path)

            try dbQueue?.write { db in
                // Check if table exists
                let tableExists = try db.tableExists(Server.databaseTableName)
                
                if !tableExists {
                    // Create new table with all columns including keyId
                    try db.create(table: Server.databaseTableName, ifNotExists: true) { t in
                        t.column("id", .text).primaryKey()
                        t.column("name", .text).notNull()
                        t.column("host", .text).notNull()
                        t.column("port", .integer).notNull().defaults(to: 22)
                        t.column("username", .text).notNull()
                        t.column("password", .text)
                        t.column("usePassword", .boolean).notNull().defaults(to: true)
                        t.column("privateKeyPath", .text)
                        t.column("keyId", .text)
                        t.column("createdAt", .datetime).notNull()
                        t.column("lastUsed", .datetime)
                        t.column("operatingSystem", .text)
                    }
                } else {
                    // Table exists - check if keyId column exists and add it if missing
                    // Try to query the column - if it fails, the column doesn't exist
                    do {
                        _ = try db.execute(sql: "SELECT keyId FROM \(Server.databaseTableName) LIMIT 1")
                    } catch {
                        // Column doesn't exist, add it
                        try db.execute(sql: "ALTER TABLE \(Server.databaseTableName) ADD COLUMN keyId TEXT")
                    }
                    
                    // Ensure operatingSystem column exists
                    do {
                        _ = try db.execute(sql: "SELECT operatingSystem FROM \(Server.databaseTableName) LIMIT 1")
                    } catch {
                        try db.execute(sql: "ALTER TABLE \(Server.databaseTableName) ADD COLUMN operatingSystem TEXT")
                    }
                }
                
                try db.create(table: SSHKey.databaseTableName, ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("name", .text).notNull()
                    t.column("privateKey", .text).notNull() // Encrypted
                    t.column("publicKey", .text)
                    t.column("createdAt", .datetime).notNull()
                }
            }
        } catch {
            print("Database setup failed: \(error)")
            // Fallback to in-memory database
            dbQueue = try? DatabaseQueue()
        }
    }

    func loadServers() {
        do {
            let encryptedServers = try dbQueue?.read { db in
                try Server.fetchAll(db)
            } ?? []

            // Decrypt passwords
            servers = encryptedServers.map { server in
                var decryptedServer = server
                if let encryptedPassword = server.password {
                    decryptedServer.password = decryptPassword(encryptedPassword)
                }
                return decryptedServer
            }
        } catch {
            print("Failed to load servers: \(error)")
            servers = []
        }
    }

    func saveServers() {
        do {
            try dbQueue?.write { db in
                // Clear existing records
                try Server.deleteAll(db)

                // Encrypt passwords and insert servers
                for server in servers {
                    var encryptedServer = server
                    if let password = server.password {
                        encryptedServer.password = encryptPassword(password)
                    }
                    try encryptedServer.insert(db)
                }
            }
        } catch {
            print("Failed to save servers: \(error)")
        }
    }

    // MARK: - Encryption Methods

    private func encryptPassword(_ password: String) -> String {
        guard let data = password.data(using: .utf8) else { return password }
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            return sealedBox.combined?.base64EncodedString() ?? password
        } catch {
            print("Encryption failed: \(error)")
            return password
        }
    }

    private func decryptPassword(_ encryptedPassword: String) -> String? {
        guard let data = Data(base64Encoded: encryptedPassword),
              let sealedBox = try? AES.GCM.SealedBox(combined: data) else {
            return encryptedPassword
        }
        do {
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return encryptedPassword
        }
    }

    func addServer(_ server: Server) {
        servers.append(server)
        saveServers()
    }

    func updateServer(_ server: Server) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }

    func updateServerOperatingSystem(serverId: UUID, detectedOS: String?) {
        guard let index = servers.firstIndex(where: { $0.id == serverId }) else { return }
        // Avoid unnecessary writes if value is unchanged
        if servers[index].operatingSystem == detectedOS { return }
        servers[index].operatingSystem = detectedOS
        saveServers()
    }

    func deleteServer(_ server: Server) {
        servers.removeAll { $0.id == server.id }
        connectedServers.removeValue(forKey: server.id)
        connectionCancellables.removeValue(forKey: server.id)
        saveServers()
    }
    
    func deleteAllServers() {
        connectedServers.values.forEach { $0.disconnect() }
        connectedServers.removeAll()
        connectionCancellables.removeAll()
        terminalHolders.removeAll()
        pendingAutoConnect = nil
        servers.removeAll()
        selectedNavigationItem = .overview
        saveServers()
    }
    
    // MARK: - Key Management
    
    func loadKeys() {
        do {
            let encryptedKeys = try dbQueue?.read { db in
                try SSHKey.fetchAll(db)
            } ?? []
            
            // Decrypt keys - filter out keys that can't be decrypted
            keys = encryptedKeys.compactMap { key in
                guard let decryptedPrivateKey = decryptKey(key.privateKey) else {
                    print("Failed to decrypt key '\(key.name)', skipping")
                    return nil
                }
                var decryptedKey = key
                decryptedKey.privateKey = decryptedPrivateKey
                if let publicKey = key.publicKey {
                    decryptedKey.publicKey = decryptKey(publicKey)
                }
                return decryptedKey
            }
        } catch {
            print("Failed to load keys: \(error)")
            keys = []
        }
    }
    
    func saveKeys() {
        do {
            try dbQueue?.write { db in
                try SSHKey.deleteAll(db)
                
                for key in keys {
                    var encryptedKey = key
                    encryptedKey.privateKey = encryptKey(key.privateKey) ?? key.privateKey
                    if let publicKey = key.publicKey {
                        encryptedKey.publicKey = encryptKey(publicKey)
                    }
                    try encryptedKey.insert(db)
                }
            }
        } catch {
            print("Failed to save keys: \(error)")
        }
    }
    
    private func encryptKey(_ key: String) -> String? {
        guard let keyData = key.data(using: .utf8) else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(keyData, using: encryptionKey)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Key encryption failed: \(error)")
            return nil
        }
    }
    
    func decryptKey(_ encryptedKey: String) -> String? {
        // First, try to decode as base64
        guard let data = Data(base64Encoded: encryptedKey) else {
            print("Key decryption failed: Not a valid base64 string")
            return nil
        }
        
        // Try to create sealed box
        guard let sealedBox = try? AES.GCM.SealedBox(combined: data) else {
            print("Key decryption failed: Could not create sealed box from data")
            return nil
        }
        
        do {
            let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                print("Key decryption failed: Could not convert decrypted data to string")
                return nil
            }
            return decryptedString
        } catch {
            print("Key decryption failed: \(error)")
            return nil
        }
    }
    
    func addKey(_ key: SSHKey) {
        keys.append(key)
        saveKeys()
    }
    
    func updateKey(_ key: SSHKey) {
        if let index = keys.firstIndex(where: { $0.id == key.id }) {
            keys[index] = key
            saveKeys()
        }
    }
    
    func deleteKey(_ key: SSHKey) {
        keys.removeAll { $0.id == key.id }
        saveKeys()
    }
    
    func getKey(by id: UUID) -> SSHKey? {
        return keys.first { $0.id == id }
    }
    
    func removeFromRecent(_ server: Server) {
        // Remove server from recent list by setting lastUsed to nil
        var updatedServer = server
        updatedServer.lastUsed = nil
        updateServer(updatedServer)
    }

    func connect(to server: Server) {
        // Update last used timestamp
        var updatedServer = server
        updatedServer.lastUsed = Date()
        updateServer(updatedServer)

        let serverId = server.id
        let manager = ConnectionManager()
        manager.detectedOS = server.operatingSystem
        manager.onDetectedOS = { [weak self] os in
            self?.updateServerOperatingSystem(serverId: serverId, detectedOS: os)
        }
        connectedServers[server.id] = manager
        connectionCancellables[server.id] = manager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        
        // Show connecting view first (not terminal yet)
        DispatchQueue.main.async {
            self.selectedNavigationItem = .server(updatedServer)
        }

        // Start connection in background
        var keyPath: String? = server.privateKeyPath
        var ephemeralPrivateKeyURL: URL? = nil
        if let keyId = server.keyId, let key = getKey(by: keyId) {
            // Key is already decrypted in memory (from loadKeys())
            // Use it directly without decrypting again
            let privateKeyContent = key.privateKey
            
            // Save key to temporary file for connection
            let tempDir = FileManager.default.temporaryDirectory
            let tempKeyFile = tempDir.appendingPathComponent("\(key.id.uuidString).pem")
            do {
                try privateKeyContent.write(to: tempKeyFile, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: tempKeyFile.path)
                keyPath = tempKeyFile.path
                ephemeralPrivateKeyURL = tempKeyFile
                print("SSH key written to temporary file: \(tempKeyFile.path), length: \(privateKeyContent.count) characters")
            } catch {
                print("Failed to write temporary key file: \(error)")
            }
        }
        
        manager.connect(
            host: server.host,
            port: server.port,
            username: server.username,
            password: server.password,
            usePassword: server.usePassword,
            privateKeyPath: keyPath,
            ephemeralPrivateKeyURL: ephemeralPrivateKeyURL,
            completion: { [weak self] in
                // Connection successful - UI will update automatically via @Published properties
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
        )
    }

    func connectOrFocusFromMenuBar(to server: Server) {
        guard let current = servers.first(where: { $0.id == server.id }) else { return }
        if let mgr = connectedServers[server.id], mgr.isConnected || mgr.isConnecting {
            DispatchQueue.main.async {
                self.selectedNavigationItem = .server(current)
            }
            return
        }
        connect(to: current)
    }

    func disconnect(from server: Server) {
        connectedServers[server.id]?.disconnect()
        connectedServers.removeValue(forKey: server.id)
        connectionCancellables.removeValue(forKey: server.id)
    }

    func getConnectionManager(for server: Server) -> ConnectionManager? {
        return connectedServers[server.id]
    }

}

final class ConnectionManager: ObservableObject {
    @Published var status: String = LocalizedStrings.statusReadyToConnect
    @Published var showTerminal: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isConnected: Bool = false
    @Published var interactiveStarted: Bool = false
    @Published var detectedOS: String? = nil
    @Published var connectionError: String? = nil
    var onDetectedOS: ((String) -> Void)?

    private var shell: NSRemoteShell?
    private var inputBuffer: String = ""
    private var bufferLock = NSLock()
    private let connectTimeoutSeconds: TimeInterval = 2
    private var connectTimeoutWorkItem: DispatchWorkItem?

    func connect(host: String, port: Int, username: String, password: String?, usePassword: Bool, privateKeyPath: String? = nil, ephemeralPrivateKeyURL: URL? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.cancelConnectTimeout()
            self.isConnecting = true
            self.status = LocalizedStrings.statusConnecting
            self.showTerminal = false
            self.connectionError = nil
            let timeout = DispatchWorkItem { [weak self] in
                guard let self = self, self.isConnecting, !self.isConnected else { return }
                self.status = LocalizedStrings.connectionFailedTitle
                self.isConnecting = false
                self.connectionError = LocalizedStrings.connectionFailedDetail(host: host, port: port)
                self.shell?.requestDisconnectAndWait()
            }
            self.connectTimeoutWorkItem = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + self.connectTimeoutSeconds, execute: timeout)
        }

        shell = NSRemoteShell()
        guard let shell = shell else {
            DispatchQueue.main.async {
                self.cancelConnectTimeout()
                self.status = LocalizedStrings.statusFailedToCreateShell
                self.isConnecting = false
                self.connectionError = LocalizedStrings.connectionErrorShellInstance
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer {
                if let url = ephemeralPrivateKeyURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            // Set shorter timeout for faster failure detection
            shell.setupConnectionHost(host)
                .setupConnectionPort(NSNumber(value: port))
                .setupConnectionTimeout(NSNumber(value: 2)) // schneller abbrechen
                .requestConnectAndWait()

            guard shell.isConnected else {
                DispatchQueue.main.async {
                    self?.cancelConnectTimeout()
                    self?.status = LocalizedStrings.connectionFailedTitle
                    self?.isConnecting = false
                    self?.connectionError = LocalizedStrings.connectionFailedDetail(host: host, port: port)
                }
                return
            }

            if let keyPath = privateKeyPath, !keyPath.isEmpty {
                print("Attempting key authentication with path: \(keyPath)")
                // try to read private key file
                let pkUrl = URL(fileURLWithPath: keyPath)
                if FileManager.default.fileExists(atPath: keyPath),
                   let keyData = try? String(contentsOf: pkUrl, encoding: .utf8) {
                    print("Key file read successfully, length: \(keyData.count) characters")
                    // Use key authentication - only pass password if usePassword is true (for passphrase-protected keys)
                    if usePassword {
                        print("Authenticating with key and password (passphrase)")
                        shell.authenticate(with: username, andPublicKey: nil, andPrivateKey: keyData, andPassword: password)
                    } else {
                        print("Authenticating with key only (no passphrase)")
                        shell.authenticate(with: username, andPublicKey: nil, andPrivateKey: keyData, andPassword: nil)
                    }
                } else {
                    print("Failed to read key file at path: \(keyPath)")
                    // fallback to password if key reading failed
                    if usePassword {
                        print("Falling back to password authentication")
                        shell.authenticate(with: username, andPassword: password ?? "")
                    } else {
                        DispatchQueue.main.async {
                            self?.cancelConnectTimeout()
                            self?.status = LocalizedStrings.statusAuthenticationFailed
                            self?.isConnecting = false
                            self?.isConnected = false
                            self?.connectionError = LocalizedStrings.connectionErrorKeyFileUnreadable
                        }
                        return
                    }
                }
            } else if usePassword {
                shell.authenticate(with: username, andPassword: password ?? "")
            } else {
                // No-auth fallback: try username only
                shell.authenticate(with: username, andPassword: password ?? "")
            }

            guard shell.isConnected, shell.isAuthenticated else {
                DispatchQueue.main.async {
                    self?.cancelConnectTimeout()
                    self?.status = LocalizedStrings.statusAuthenticationFailed
                    self?.isConnecting = false
                    self?.isConnected = false
                    self?.connectionError = LocalizedStrings.connectionErrorAuthFailed
                }
                return
            }

            DispatchQueue.main.async {
                self?.cancelConnectTimeout()
                self?.status = LocalizedStrings.statusConnected
                self?.isConnecting = false
                self?.isConnected = true
                self?.showTerminal = true
                self?.connectionError = nil
                if AppSettings.shared.detectOperatingSystem {
                    self?.detectedOS = LocalizedStrings.osDetecting
                }
            }

            DispatchQueue.main.async {
                self?.status = LocalizedStrings.statusConnectedOpeningTerminal
                // notify caller that connection reached authenticated state
                completion?()
            }

            // Trigger OS detection in background if enabled
            if AppSettings.shared.detectOperatingSystem {
                self?.detectOperatingSystem(using: shell)
            }
        }
    }

    func disconnect() {
        cancelConnectTimeout()
        guard let shell = shell else { return }
        DispatchQueue.global().async {
            shell.requestDisconnectAndWait()
            DispatchQueue.main.async { [weak self] in
                self?.status = LocalizedStrings.statusDisconnected
                self?.isConnected = false
                self?.interactiveStarted = false
            }
        }
    }

    func appendToInputBuffer(_ input: String) {
        bufferLock.lock()
        inputBuffer += input
        bufferLock.unlock()
    }

    func getInputBuffer() -> String {
        bufferLock.lock()
        let buffer = inputBuffer
        inputBuffer = ""
        bufferLock.unlock()
        return buffer
    }

    private func cancelConnectTimeout() {
        connectTimeoutWorkItem?.cancel()
        connectTimeoutWorkItem = nil
    }

    func startInteractiveShell(with terminalView: STerminalView) {
        // prevent starting multiple interactive channels
        guard !interactiveStarted else {
            // Just ensure buffer chain is connected for output
            return
        }
        guard let shell = shell, shell.isConnected, shell.isAuthenticated else {
            terminalView.write(LocalizedStrings.terminalNoActiveSSH + "\r\n")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // mark interactive started immediately to prevent race conditions
            DispatchQueue.main.async {
                 self?.interactiveStarted = true
            }

            // Detect OS if enabled in settings
            if AppSettings.shared.detectOperatingSystem {
                // TODO: Implement OS detection via shell command
                // For now, just set a placeholder
                DispatchQueue.main.async {
                    self?.detectedOS = LocalizedStrings.osDetecting
                }
            }

            shell.begin(withTerminalType: "xterm",
                withOnCreate: {
                    print("SSH shell channel opened")
                },
                withTerminalSize: {
                    // Return terminal size
                    return terminalView.requestTerminalSize()
                },
                withWriteDataBuffer: { [weak self] in
                    // Return buffered input from terminal
                    return self?.getInputBuffer() ?? ""
                },
                withOutputDataBuffer: { output in
                    // Write output to terminal
                    DispatchQueue.main.async {
                        terminalView.write(output)
                    }
                },
                withContinuationHandler: { [weak self] in
                    // Continue while connected
                    return self?.isConnected ?? false
                }
            )
            DispatchQueue.main.async { [weak self] in
                self?.status = LocalizedStrings.statusInteractiveShellClosed
                // Do NOT reset interactiveStarted here to prevent auto-reconnect loops on tab switch
                // Only reset on explicit disconnect
            }
        }
    }

    // TODO: Implement OS detection
    // This requires extending NSRemoteShell or using a different approach
    // For now, OS detection is disabled
    private func detectOperatingSystem(using shell: NSRemoteShell) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let script = """
            (uname -srm 2>/dev/null || uname -a 2>/dev/null || echo "Unknown") && \
            if [ -f /etc/os-release ]; then \
              . /etc/os-release 2>/dev/null; \
              echo "${PRETTY_NAME:-$NAME $VERSION}"; \
            elif command -v sw_vers >/dev/null 2>&1; then \
              sw_vers -productName && sw_vers -productVersion; \
            fi
            """
            var buffer = ""
            _ = shell.beginExecute(
                withCommand: script,
                withTimeout: NSNumber(value: 5),
                withOnCreate: {},
                withOutput: { line in
                    buffer.append(line)
                    buffer.append("\n")
                },
                withContinuationHandler: { true }
            )

            let lines = buffer
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // heuristically pick the most specific line (prefer PRETTY_NAME if present)
            let osString: String
            if lines.count >= 2 {
                osString = lines[1]
            } else if let first = lines.first {
                osString = first
            } else {
                osString = LocalizedStrings.osUnknown
            }

            let displayOS: String
            if osString.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare("unknown") == .orderedSame {
                displayOS = LocalizedStrings.osUnknown
            } else {
                displayOS = osString
            }

            DispatchQueue.main.async {
                self?.detectedOS = displayOS
                self?.onDetectedOS?(displayOS)
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if #available(macOS 13.0, *) {
                    ContentSplitView13(viewModel: viewModel)
                } else {
                    ContentSplitViewLegacy(viewModel: viewModel)
                }
            }
            
            if settings.showStatusBar {
                StatusBarView(viewModel: viewModel)
            }
        }
        .onAppear {
            if viewModel.selectedNavigationItem == nil {
                viewModel.selectedNavigationItem = .overview
            }
        }
        .sheet(isPresented: $viewModel.showAddServerSheet) {
            AddServerSheet(viewModel: viewModel, editingServer: nil)
        }
        .onAppear {
            // Mindestfenstergröße durchsetzen (WindowGroup selbst lässt sonst kleiner zu)
            let minSize = NSSize(width: 420, height: 460)
            NSApp.windows.forEach { $0.minSize = minSize }
        }
        .sheet(item: $viewModel.showEditServerSheet) { server in
            AddServerSheet(viewModel: viewModel, editingServer: server)
        }
        .sheet(item: $viewModel.showDeleteConfirmation) { server in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(LocalizedStrings.deleteServer)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.windowBackgroundColor))

                Divider()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStrings.deleteConfirmation(server.displayName))
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(LocalizedStrings.deleteWarning)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Footer
                HStack(spacing: 12) {
                    Button {
                        viewModel.showDeleteConfirmation = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text(LocalizedStrings.cancel)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        viewModel.deleteServer(server)
                        viewModel.showDeleteConfirmation = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text(LocalizedStrings.delete)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .frame(minWidth: 500, minHeight: 220)
        }
        .sheet(isPresented: $viewModel.showDeleteAllServersConfirmation) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(LocalizedStrings.deleteAllServers)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.windowBackgroundColor))

                Divider()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStrings.deleteAllServersDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(LocalizedStrings.deleteWarning)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Footer
                HStack(spacing: 12) {
                    Button {
                        viewModel.showDeleteAllServersConfirmation = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text(LocalizedStrings.cancel)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        viewModel.deleteAllServers()
                        viewModel.showDeleteAllServersConfirmation = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text(LocalizedStrings.deleteAllServers)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(viewModel.servers.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .frame(minWidth: 500, minHeight: 220)
        }
        .sheet(item: $viewModel.showDeleteKeyConfirmation) { key in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(LocalizedStrings.deleteKey)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.windowBackgroundColor))

                Divider()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStrings.deleteConfirmation(key.name))
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(LocalizedStrings.deleteWarning)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Footer
                HStack(spacing: 12) {
                    Button {
                        viewModel.showDeleteKeyConfirmation = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text(LocalizedStrings.cancel)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        viewModel.deleteKey(key)
                        viewModel.showDeleteKeyConfirmation = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text(LocalizedStrings.delete)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .frame(minWidth: 500, minHeight: 220)
        }
        // Min-Größe drastisch reduziert, um responsives Layout nicht zu blockieren
                .frame(minWidth: 420, minHeight: 460)
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: AppViewModel

    private func formatLastUsed(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func isServerSelected(_ server: Server) -> Bool {
        guard let selected = viewModel.selectedNavigationItem else { return false }
        switch selected {
        case .server(let s):
            return s.id == server.id
        default:
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // let selectedServerId: UUID? = {
            //     if case .server(let s) = viewModel.selectedNavigationItem { return s.id }
            //     return nil
            // }()

            List {
                // Overview tab
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.selectedNavigationItem = .overview
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 14))
                        Text(LocalizedStrings.overview)
                            .font(.system(size: 13, weight: .regular))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(viewModel.selectedNavigationItem == .overview ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
                .animation(.easeInOut(duration: 0.15), value: viewModel.selectedNavigationItem)
                
                // Keys tab
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.selectedNavigationItem = .keys
                    }
                } label: {
                    HStack {
                        Image(systemName: "key")
                            .font(.system(size: 14))
                        Text(LocalizedStrings.keys)
                            .font(.system(size: 13, weight: .regular))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(viewModel.selectedNavigationItem == .keys ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
                .animation(.easeInOut(duration: 0.15), value: viewModel.selectedNavigationItem)

                // Connected servers as tabs (only truly connected ones)
                if viewModel.connectedServers.values.contains(where: { $0.isConnected }) {
                            Text(LocalizedStrings.activeConnections)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .padding(.top, 8)

                    ForEach(viewModel.servers.filter {
                        if let mgr = viewModel.connectedServers[$0.id] {
                            return mgr.isConnected
                        }
                        return false
                    }) { server in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.selectedNavigationItem = .server(server)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "terminal")
                                    .font(.system(size: 14))
                                Text(server.displayName)
                                    .font(.system(size: 13, weight: .regular))
                                Spacer()
                                if let manager = viewModel.getConnectionManager(for: server),
                                   manager.isConnected {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(isServerSelected(server) ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedNavigationItem)
                        .contextMenu {
                            Button {
                                viewModel.disconnect(from: server)
                                // Switch back to overview if this was the active tab
                                if viewModel.selectedNavigationItem == .server(server) {
                                    viewModel.selectedNavigationItem = .overview
                                }
                            } label: {
                                Label(LocalizedStrings.disconnect, systemImage: "stop.circle")
                            }
                        }
                    }
                }

                // Recent connections (exclude currently active connections)
                let activeServerIds = Set(viewModel.connectedServers.keys)
                let recentServers = viewModel.servers
                    .filter { $0.lastUsed != nil && !activeServerIds.contains($0.id) }
                    .sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
                    .prefix(8) // Show max 8 recent connections

                if !recentServers.isEmpty {
                            Text(LocalizedStrings.recent)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .padding(.top, 8)

                    ForEach(recentServers, id: \.id) { server in
                        RecentServerItem(
                            server: server,
                            viewModel: viewModel,
                            isSelected: isServerSelected(server),
                            formatLastUsed: formatLastUsed
                        )
                    }
                }
            }
            .listStyle(.sidebar)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .padding(.top, 24)
            .frame(maxWidth: 320, alignment: .leading)
            .onAppear {
                if viewModel.selectedNavigationItem == nil {
                    viewModel.selectedNavigationItem = .overview
                }
            }

            Spacer()
        }
        .frame(minWidth: 200, maxWidth: 320, alignment: .topLeading)
    }
}

@available(macOS 13.0, *)
private struct ContentSplitView13: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject private var settings = AppSettings.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var overviewMode: OverviewViewMode = .grid

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.selectedNavigationItem {
        case .overview, .none:
            ServerOverviewView(viewModel: viewModel, viewMode: $overviewMode)
        case .keys:
            KeysView(viewModel: viewModel)
        case .server(let server):
            TerminalContainerView(server: server, viewModel: viewModel)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(viewModel: viewModel)
            } detail: {
                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationSplitViewStyle(.balanced)
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
            .onAppear {
                updateColumnVisibility(for: proxy.size.width)
            }
            .onChange(of: proxy.size.width) { newWidth in
                updateColumnVisibility(for: newWidth)
            }
            .onChange(of: settings.showSidebar) { _ in
                updateColumnVisibility(for: proxy.size.width)
            }
        }
    }
    
    private func updateColumnVisibility(for width: CGFloat) {
        let sidebarMin: CGFloat = 200
        let padding: CGFloat = 40
        let spacing: CGFloat = 20
        let minCardWidth: CGFloat = 240
        let requiredForTwo = sidebarMin + padding + (minCardWidth * 2) + spacing
        let allowSidebar = settings.showSidebar && width >= requiredForTwo
        columnVisibility = allowSidebar ? .all : .detailOnly
    }
}

private struct StatusBarView: View {
    @ObservedObject var viewModel: AppViewModel
    
    private static let lastUsedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var totalServers: Int { viewModel.servers.count }
    private var activeConnections: Int { viewModel.connectedServers.values.filter { $0.isConnected }.count }
    private var lastUsedText: String {
        guard let last = viewModel.servers.compactMap({ $0.lastUsed }).max() else {
            return "\(LocalizedStrings.lastUsed): –"
        }
        return "\(LocalizedStrings.lastUsed): " + StatusBarView.lastUsedFormatter.string(from: last)
    }
    
    private func statusChip(icon: String, text: String, color: Color = .primary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color == .primary ? .secondary : color)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(6)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            statusChip(icon: "square.stack.3d.up", text: LocalizedStrings.statusBarServerCount(totalServers))
            statusChip(icon: "bolt.fill", text: LocalizedStrings.statusBarActiveCount(activeConnections), color: activeConnections > 0 ? .green : .primary)
            Spacer()
            statusChip(icon: "clock", text: lastUsedText, color: .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor).opacity(0.95))
        .overlay(
            Divider(),
            alignment: .top
        )
    }
}

private struct ContentSplitViewLegacy: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject private var settings = AppSettings.shared
    @State private var overviewMode: OverviewViewMode = .grid

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.selectedNavigationItem {
        case .overview, .none:
            ServerOverviewView(viewModel: viewModel, viewMode: $overviewMode)
        case .keys:
            KeysView(viewModel: viewModel)
        case .server(let server):
            TerminalContainerView(server: server, viewModel: viewModel)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let sidebarMin: CGFloat = 200
            let padding: CGFloat = 40
            let spacing: CGFloat = 20
            let minCardWidth: CGFloat = 240
            let requiredForTwo = sidebarMin + padding + (minCardWidth * 2) + spacing
            let canShowSidebar = proxy.size.width >= requiredForTwo
            let effectiveShowSidebar = settings.showSidebar && canShowSidebar

            NavigationView {
                if effectiveShowSidebar {
                    SidebarView(viewModel: viewModel)
                        .frame(minWidth: sidebarMin, idealWidth: 240, maxWidth: 320)
                }

                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct RecentServerItem: View {
    let server: Server
    @ObservedObject var viewModel: AppViewModel
    let isSelected: Bool
    let formatLastUsed: (Date) -> String
    @State private var isHovered = false
    @State private var isToolsHovered = false
    
    var body: some View {
        Button {
            // Safety check: ensure server still exists before navigating
            guard let currentServer = viewModel.servers.first(where: { $0.id == server.id }) else {
                // Server was deleted, don't navigate
                return
            }
            // Navigate to server detail and show start prompt instead of auto-connecting
            // Use current server instance to ensure we have the latest data
            DispatchQueue.main.async {
                viewModel.selectedNavigationItem = .server(currentServer)
                viewModel.pendingAutoConnect = currentServer.id
            }
        } label: {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                Text(server.displayName)
                    .font(.system(size: 13, weight: .regular))
                Spacer()
                if let lastUsed = server.lastUsed {
                    Text("\(LocalizedStrings.lastUsed): \(formatLastUsed(lastUsed))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedNavigationItem)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                viewModel.connect(to: server)
            } label: {
                Label(LocalizedStrings.connect, systemImage: "play.fill")
            }
            
            Divider()
            
            Button {
                viewModel.removeFromRecent(server)
            } label: {
                Label(LocalizedStrings.delete, systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

enum OverviewViewMode: String {
    case grid
    case list
}

struct ServerOverviewView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var viewMode: OverviewViewMode
    @State private var isOverflowHovered = false

    // Berechnet die Spaltenanzahl diskret, um konstantes Spacing zu wahren
    private func columns(for width: CGFloat) -> [GridItem] {
        let padding: CGFloat = 48    // 24 links + 24 rechts
        let spacing: CGFloat = 20
        let minCardWidth: CGFloat = 320
        let maxColumns = 4

        let available = max(width - padding, 0)
        let calculated = Int((available + spacing) / (minCardWidth + spacing))
        let count = max(1, min(maxColumns, calculated))

        return Array(
            repeating: GridItem(.flexible(minimum: minCardWidth), spacing: spacing, alignment: .top),
            count: count
        )
    }

    var body: some View {
        Group {
            if viewModel.servers.isEmpty {
                // Center empty state in the available detail area
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    EmptyStateView(viewModel: viewModel)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(LocalizedStrings.yourServers)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.top, 24)

                            if viewMode == .grid {
                                LazyVGrid(columns: columns(for: geometry.size.width), spacing: 20) {
                                    ForEach(viewModel.servers) { server in
                                        ServerCardView(server: server, viewModel: viewModel)
                                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200, alignment: .leading)
                                    }
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(viewModel.servers) { server in
                                        ServerListView(server: server, viewModel: viewModel)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24) // einheitliche Einrückung für Titel und Grid
                        .padding(.bottom, 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Ensure grid view is active by default
            if viewMode != .grid {
                viewMode = .grid
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    // Grid/List toggle buttons grouped together
                    HStack(spacing: 4) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewMode = .grid
                            }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 28, height: 28)
                        .foregroundColor(viewMode == .grid ? .accentColor : .secondary)
                        .background(viewMode == .grid ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewMode = .list
                            }
                        } label: {
                            Image(systemName: "list.dash")
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 28, height: 28)
                        .foregroundColor(viewMode == .list ? .accentColor : .secondary)
                        .background(viewMode == .list ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                    }
                    
                    Button {
                        viewModel.showAddServerSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    
                    Menu {
                        Button {
                            viewModel.showDeleteAllServersConfirmation = true
                        } label: {
                            Label(LocalizedStrings.deleteAllServers, systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.secondary)
                    .background(isOverflowHovered ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
                    .onHover { hovering in
                        isOverflowHovered = hovering
                    }
                    .disabled(viewModel.servers.isEmpty)
                }
                .padding(.horizontal, MainWindowToolbarInsets.horizontal)
            }
        }
    }
}

struct ServerCardView: View {
    let server: Server
    @ObservedObject var viewModel: AppViewModel
    @State private var isHovered = false
    // Tools state
    @State private var showingToolsSheet = false
    @State private var selectedTool: String? = nil // "ping" or "traceroute"
    @State private var toolOutput: [String] = []
    @State private var toolProcess: Process? = nil
    @State private var isToolsHovered = false

    private func lastUsedText(for server: Server) -> String {
        if let lastUsed = server.lastUsed {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "\(LocalizedStrings.lastUsed): \(formatter.string(from: lastUsed))"
        } else {
            return LocalizedStrings.neverUsed
        }
    }

    private func formatLastUsed(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Primary Connect/Disconnect Button
            if viewModel.connectedServers[server.id]?.isConnected == true {
                Button {
                    viewModel.disconnect(from: server)
                } label: {
                    HStack {
                        Image(systemName: "stop.circle")
                        Text(LocalizedStrings.disconnect)
                    }
                    .frame(width: 140, height: 24)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .controlSize(.large)
            } else {
                Button {
                    viewModel.connect(to: server)
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text(LocalizedStrings.connect)
                    }
                    .frame(width: 140, height: 24)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.connectedServers[server.id]?.isConnecting ?? false)
                .controlSize(.large)
            }

            // Edit button (icon)
            Button {
                viewModel.showEditServerSheet = server
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            // Delete button (icon)
            Button {
                viewModel.showDeleteConfirmation = server
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .controlSize(.large)

            Spacer()

            // Tools Menu (Ping, Traceroute)
            Menu {
                Button {
                    startPing()
                } label: {
                    Label(LocalizedStrings.ping, systemImage: "dot.radiowaves.right")
                }
                Button {
                    startTraceroute()
                } label: {
                    Label(LocalizedStrings.traceroute, systemImage: "arrow.swap")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 14))
                .frame(width: 48, height: 24)
                .background(isToolsHovered ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isToolsHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isToolsHovered = hovering
                    }
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .menuStyle(BorderlessButtonMenuStyle())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with server name and status
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .padding(.top, 2)

                Text(server.displayName)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                if viewModel.connectedServers[server.id]?.isConnected == true {
                    Text(LocalizedStrings.active)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Divider()
                .padding(.horizontal, -16)

            // Connection details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(LocalizedStrings.hostIP):")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(server.host)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 4) {
                    Text("\(LocalizedStrings.user):")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(server.username)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }

                HStack(spacing: 4) {
                    Text("\(LocalizedStrings.port):")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text(String(server.port))
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
            }

            if let os = server.operatingSystem, !os.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "cube")
                        .font(.system(size: 12, weight: .semibold))
                    Text(os)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(8)
            } else {
                // Platzhalter, damit Karten auch ohne OS-Info gleich hoch bleiben
                Color.clear
                    .frame(height: 16)
                    .padding(.vertical, 8)
            }

            // Last used info
            Text(lastUsedText(for: server))
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            actionButtons
        }
        .padding(16)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHovered
                        ? Color.accentColor.opacity(0.3)
                        : Color.gray.opacity(0.1),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .shadow(
            color: isHovered
                ? Color.black.opacity(0.15)
                : Color.black.opacity(0.1),
            radius: isHovered ? 3 : 2,
            x: 0,
            y: isHovered ? 2 : 1
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            // 1. Verbinden / Trennen
            if viewModel.connectedServers[server.id]?.isConnected == true {
                Button {
                    viewModel.disconnect(from: server)
                } label: {
                    Label(LocalizedStrings.disconnect, systemImage: "stop.circle")
                }
            } else {
                Button {
                    viewModel.connect(to: server)
                } label: {
                    Label(LocalizedStrings.connect, systemImage: "globe")
                }
            }
            
            Divider()
            
            // 2. Werkzeuge als Untermenü
            Menu(LocalizedStrings.tools) {
                Button {
                    startPing()
                } label: {
                    Label(LocalizedStrings.ping, systemImage: "dot.radiowaves.right")
                }

                Button {
                    startTraceroute()
                } label: {
                    Label(LocalizedStrings.traceroute, systemImage: "arrow.swap")
                }
            }
            
            Divider()
            
            // 3. Bearbeiten / Löschen
            Button {
                viewModel.showEditServerSheet = server
            } label: {
                Label(LocalizedStrings.editServer, systemImage: "slider.horizontal.3")
            }
            
            Button {
                viewModel.showDeleteConfirmation = server
            } label: {
                Label(LocalizedStrings.delete, systemImage: "trash")
            }
            .foregroundColor(.red)
        }
        .sheet(isPresented: $showingToolsSheet, onDismiss: {
            stopToolProcess()
            toolOutput = []
            selectedTool = nil
        }) {
            ToolsSheet(server: server, tool: selectedTool ?? "", output: $toolOutput, isPresented: $showingToolsSheet, stopAction: {
                stopToolProcess()
            })
        }
    }

    // MARK: - Tools helpers
    private func startPing() {
        selectedTool = "ping"
        toolOutput = []
        showingToolsSheet = true

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/sbin/ping")
        proc.arguments = ["-c", "0", server.host] // on mac, -c 0 might run indefinitely; use no count to keep streaming - use "-c", "5" for limited? use continuous by omitting -c
        // Use continuous ping by omitting -c
        proc.arguments = [server.host]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        toolProcess = proc

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let s = String(data: data, encoding: .utf8) {
                let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
                DispatchQueue.main.async {
                    toolOutput.append(contentsOf: lines)
                }
            }
        }

        proc.terminationHandler = { _ in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                toolOutput.append("-- finished --")
            }
        }

        do {
            try proc.run()
        } catch {
            DispatchQueue.main.async {
                toolOutput.append(LocalizedStrings.toolFailedToStartPing(String(describing: error)))
            }
        }
    }

    private func startTraceroute() {
        selectedTool = "traceroute"
        toolOutput = []
        showingToolsSheet = true

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/traceroute")
        proc.arguments = [server.host]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        toolProcess = proc

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let s = String(data: data, encoding: .utf8) {
                let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
                DispatchQueue.main.async {
                    toolOutput.append(contentsOf: lines)
                }
            }
        }

        proc.terminationHandler = { _ in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                toolOutput.append("-- finished --")
            }
        }

        do {
            try proc.run()
        } catch {
            DispatchQueue.main.async {
                toolOutput.append(LocalizedStrings.toolFailedToStartTraceroute(String(describing: error)))
            }
        }
    }

    private func stopToolProcess() {
        if let p = toolProcess {
            if p.isRunning {
                p.terminate()
            }
            toolProcess = nil
        }
    }
}

struct ServerListView: View {
    let server: Server
    @ObservedObject var viewModel: AppViewModel
    @State private var isHovered = false
    // Tools state
    @State private var showingToolsSheet = false
    @State private var selectedTool: String? = nil // "ping" or "traceroute"
    @State private var toolOutput: [String] = []
    @State private var toolProcess: Process? = nil
    @State private var isToolsHovered = false
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Primary Connect/Disconnect Button
            if viewModel.connectedServers[server.id]?.isConnected == true {
                Button {
                    viewModel.disconnect(from: server)
                } label: {
                    HStack {
                        Image(systemName: "stop.circle")
                        Text(LocalizedStrings.disconnect)
                    }
                    .frame(height: 24)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .controlSize(.large)
            } else {
                Button {
                    viewModel.connect(to: server)
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text(LocalizedStrings.connect)
                    }
                    .frame(height: 24)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.connectedServers[server.id]?.isConnecting ?? false)
                .controlSize(.large)
            }

            // Edit button (icon)
            Button {
                viewModel.showEditServerSheet = server
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            // Delete button (icon)
            Button {
                viewModel.showDeleteConfirmation = server
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .controlSize(.large)

            // Tools Menu (Ping, Traceroute)
            Menu {
                Button {
                    startPing()
                } label: {
                    Label(LocalizedStrings.ping, systemImage: "dot.radiowaves.right")
                }
                Button {
                    startTraceroute()
                } label: {
                    Label(LocalizedStrings.traceroute, systemImage: "arrow.swap")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 14))
                .frame(width: 48, height: 24)
                .background(isToolsHovered ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isToolsHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isToolsHovered = hovering
                    }
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .menuStyle(BorderlessButtonMenuStyle())
        }
    }

    private var listContent: some View {
        HStack(spacing: 12) {
            // Icon (gleich groß wie im Grid-Mode)
            Image(systemName: "slider.horizontal.below.rectangle")
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            // Main info (Name + user@host:port)
            VStack(alignment: .leading, spacing: 2) {
                Text(server.displayName)
                    .font(.system(size: 13, weight: .semibold))
                Text("\(server.username)@\(server.host):\(String(server.port))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .layoutPriority(1)

            Spacer(minLength: 16)

            // OS-Badge rechts vom Name/Adresse-Block, vertikal zentriert
            if let os = server.operatingSystem, !os.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "cube")
                        .font(.system(size: 11, weight: .semibold))
                    Text(os)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 8)
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(6)
                .frame(maxHeight: .infinity, alignment: .center)
            }

            // Status badge
            if viewModel.connectedServers[server.id]?.isConnected == true {
                Text(LocalizedStrings.active)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(6)
            }

            // Actions (like grid view) - all buttons right-aligned
            actionButtons
        }
    }
    
    var body: some View {
        listContent
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isHovered
                            ? Color.accentColor.opacity(0.3)
                            : Color.gray.opacity(0.1),
                        lineWidth: isHovered ? 1.5 : 1
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
        .sheet(isPresented: $showingToolsSheet, onDismiss: {
            stopToolProcess()
            toolOutput = []
            selectedTool = nil
        }) {
            ToolsSheet(server: server, tool: selectedTool ?? "", output: $toolOutput, isPresented: $showingToolsSheet, stopAction: {
                stopToolProcess()
            })
        }
        .contextMenu {
            // Verbinden / Trennen
            if viewModel.connectedServers[server.id]?.isConnected == true {
                Button {
                    viewModel.disconnect(from: server)
                } label: {
                    Label(LocalizedStrings.disconnect, systemImage: "stop.circle")
                }
            } else {
                Button {
                    viewModel.connect(to: server)
                } label: {
                    Label(LocalizedStrings.connect, systemImage: "globe")
                }
            }
            
            Divider()
            
            Menu(LocalizedStrings.tools) {
                Button {
                    startPing()
                } label: {
                    Label(LocalizedStrings.ping, systemImage: "dot.radiowaves.right")
                }
                Button {
                    startTraceroute()
                } label: {
                    Label(LocalizedStrings.traceroute, systemImage: "arrow.swap")
                }
            }
            
            Divider()
            
            Button {
                viewModel.showEditServerSheet = server
            } label: {
                Label(LocalizedStrings.editServer, systemImage: "slider.horizontal.3")
            }
            
            Button {
                viewModel.showDeleteConfirmation = server
            } label: {
                Label(LocalizedStrings.delete, systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Tools helpers
    private func startPing() {
        selectedTool = "ping"
        toolOutput = []
        showingToolsSheet = true

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/sbin/ping")
        proc.arguments = [server.host]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        toolProcess = proc

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let s = String(data: data, encoding: .utf8) {
                let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
                DispatchQueue.main.async {
                    toolOutput.append(contentsOf: lines)
                }
            }
        }

        proc.terminationHandler = { _ in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                toolOutput.append("-- finished --")
            }
        }

        do {
            try proc.run()
        } catch {
            DispatchQueue.main.async {
                toolOutput.append(LocalizedStrings.toolFailedToStartPing(String(describing: error)))
            }
        }
    }

    private func startTraceroute() {
        selectedTool = "traceroute"
        toolOutput = []
        showingToolsSheet = true

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/traceroute")
        proc.arguments = [server.host]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        toolProcess = proc

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.count > 0, let s = String(data: data, encoding: .utf8) {
                let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
                DispatchQueue.main.async {
                    toolOutput.append(contentsOf: lines)
                }
            }
        }

        proc.terminationHandler = { _ in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                toolOutput.append("-- finished --")
            }
        }

        do {
            try proc.run()
        } catch {
            DispatchQueue.main.async {
                toolOutput.append(LocalizedStrings.toolFailedToStartTraceroute(String(describing: error)))
            }
        }
    }

    private func stopToolProcess() {
        if let p = toolProcess {
            if p.isRunning {
                p.terminate()
            }
            toolProcess = nil
        }
    }
}

struct EmptyStateView: View {
    @ObservedObject var viewModel: AppViewModel
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "desktopcomputer.and.arrow.down")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text(LocalizedStrings.noServersYet)
                    .font(.title)
                    .fontWeight(.semibold)

                Text(LocalizedStrings.addFirstServer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)

                Button {
                    viewModel.showAddServerSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(LocalizedStrings.addServer)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(LocalizedStrings.sshTerminal)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(LocalizedStrings.connectToRemote)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStrings.features)
                    .font(.headline)

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizedStrings.secureConnections)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizedStrings.interactiveTerminal)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizedStrings.passwordAndKeyAuth)
                }
            }
            .frame(maxWidth: 300)

            Spacer()
        }
        .padding()
    }
}

struct AddServerSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let editingServer: Server?

    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var password = ""
    @State private var usePassword = true
    @State private var selectedKeyId: UUID? = nil

    var body: some View {
        // compute selected key name separately to help the compiler with type inference
        let selectedKeyName: String = {
            if let id = selectedKeyId, let key = viewModel.getKey(by: id) {
                return key.name
            }
            return LocalizedStrings.noKeySelected
        }()

        VStack(spacing: 0) {
            // Header
            HStack {
                Text(editingServer == nil ? LocalizedStrings.addServer : LocalizedStrings.editServer)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Server Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStrings.serverDetails)
                                .font(.headline)
                                .foregroundColor(.primary)

                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStrings.nameOptional)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    TextField("", text: $name)
                                        .textFieldStyle(.plain)
                                        .padding(8)
                                        .background(Color(.textBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStrings.hostIP)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    TextField("", text: $host)
                                        .textFieldStyle(.plain)
                                        .padding(8)
                                        .background(Color(.textBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStrings.port)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    TextField("", text: $port)
                                        .textFieldStyle(.plain)
                                        .padding(8)
                                        .background(Color(.textBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }

                        // Authentication Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStrings.authentication)
                                .font(.headline)
                                .foregroundColor(.primary)

                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStrings.username)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    TextField("", text: $username)
                                        .textFieldStyle(.plain)
                                        .padding(8)
                                        .background(Color(.textBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }

                                HStack {
                                    Text(LocalizedStrings.usePassword)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Toggle("", isOn: $usePassword)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.small)
                                }
                                .padding(.vertical, 4)

                                if usePassword {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(LocalizedStrings.password)
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                        SecureField("", text: $password)
                                            .textFieldStyle(.plain)
                                            .padding(8)
                                            .background(Color(.textBackgroundColor))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(LocalizedStrings.privateKey)
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                        HStack(spacing: 8) {
                                            Menu {
                                                Button {
                                                    selectedKeyId = nil
                                                } label: {
                                                    Text(LocalizedStrings.pickerNone)
                                                }
                                                ForEach(viewModel.keys) { key in
                                                    Button {
                                                        selectedKeyId = key.id
                                                    } label: {
                                                        HStack {
                                                            Text(key.name)
                                                            if selectedKeyId == key.id {
                                                                Spacer()
                                                                Image(systemName: "checkmark")
                                                            }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                Text(selectedKeyName)
                                                    .foregroundColor(selectedKeyId == nil ? .secondary : .primary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(8)
                                                    .background(Color(.textBackgroundColor))
                                                    .cornerRadius(6)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                    )
                                            }

                                            Button {
                                                viewModel.showNewKeySheet = true
                                            } label: {
                                                Image(systemName: "plus")
                                            }
                                            .buttonStyle(.bordered)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button {
                    viewModel.showAddServerSheet = false
                    viewModel.showEditServerSheet = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                        Text(LocalizedStrings.cancel)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    saveOnly()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text(LocalizedStrings.save)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .disabled(!isValidForm)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 480, height: 600)
        .onAppear {
            if let server = editingServer {
                // Pre-fill fields for editing
                name = server.name
                host = server.host
                port = String(server.port)
                username = server.username
                password = server.password ?? ""
                usePassword = server.usePassword
                selectedKeyId = server.keyId
            }
        }
        .sheet(isPresented: $viewModel.showNewKeySheet) {
            NewKeySheet(viewModel: viewModel)
        }
    }

    private var isValidForm: Bool {
        !host.isEmpty && !username.isEmpty && (usePassword ? (!password.isEmpty || (editingServer?.password?.isEmpty == false)) : true)
    }

    private func saveAndConnect() {
        if let editingServer = editingServer {
            // Update existing server
            var updatedServer = editingServer
            updatedServer.name = name
            updatedServer.host = host
            updatedServer.port = Int(port) ?? 22
            updatedServer.username = username
            updatedServer.password = usePassword ? password : nil
            updatedServer.usePassword = usePassword
            updatedServer.keyId = usePassword ? nil : selectedKeyId

            viewModel.updateServer(updatedServer)

            // If server was connected, reconnect with new settings
            if viewModel.connectedServers[editingServer.id] != nil {
                viewModel.disconnect(from: editingServer)
                viewModel.connect(to: updatedServer)
            }
        } else {
            // Create new server
            let server = Server(
                name: name,
                host: host,
                port: Int(port) ?? 22,
                username: username,
                password: usePassword ? password : nil,
                usePassword: usePassword,
                keyId: usePassword ? nil : selectedKeyId
            )
            viewModel.addServer(server)
            viewModel.connect(to: server)
        }

        viewModel.showAddServerSheet = false
        viewModel.showEditServerSheet = nil
    }

    private func saveOnly() {
        if let editingServer = editingServer {
            // Update existing server
            var updatedServer = editingServer
            updatedServer.name = name
            updatedServer.host = host
            updatedServer.port = Int(port) ?? 22
            updatedServer.username = username
            updatedServer.password = usePassword ? password : nil
            updatedServer.usePassword = usePassword
            updatedServer.keyId = usePassword ? nil : selectedKeyId

            viewModel.updateServer(updatedServer)
        } else {
            // Create new server
            let server = Server(
                name: name,
                host: host,
                port: Int(port) ?? 22,
                username: username,
                password: usePassword ? password : nil,
                usePassword: usePassword,
                keyId: usePassword ? nil : selectedKeyId
            )
            viewModel.addServer(server)
        }

        viewModel.showAddServerSheet = false
        viewModel.showEditServerSheet = nil
    }
}

struct TerminalContainerView: View {
    let server: Server
    @ObservedObject var viewModel: AppViewModel
    
    // Get the current server instance from viewModel to ensure we have the latest data
    private var currentServer: Server? {
        viewModel.servers.first(where: { $0.id == server.id })
    }

    var body: some View {
        Group {
            if let currentServer = currentServer {
                if let manager = viewModel.getConnectionManager(for: currentServer) {
                    TerminalContainerViewInternal(server: currentServer, viewModel: viewModel, manager: manager)
                } else if viewModel.pendingAutoConnect == currentServer.id {
                    VStack(spacing: 16) {
                        Spacer()

                        VStack(spacing: 12) {
                            Text(LocalizedStrings.startTerminalPrompt(currentServer.displayName))
                                .font(.headline)
                                .foregroundColor(.secondary)

                            // Server details
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(LocalizedStrings.hostIP):")
                                        .foregroundColor(.secondary)
                                    Text(currentServer.host)
                                        .foregroundColor(.primary)
                                }
                                HStack {
                                    Text("\(LocalizedStrings.user):")
                                        .foregroundColor(.secondary)
                                    Text(currentServer.username)
                                        .foregroundColor(.primary)
                                }
                                HStack {
                                    Text("\(LocalizedStrings.port):")
                                        .foregroundColor(.secondary)
                                    Text(String(currentServer.port))
                                        .foregroundColor(.primary)
                                }
                            }
                            .font(.subheadline)
                            .padding()
                            .background(Color(.windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)

                            HStack(spacing: 12) {
                                Button {
                                    viewModel.pendingAutoConnect = nil
                                    viewModel.selectedNavigationItem = .overview
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle")
                                        Text(LocalizedStrings.cancel)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    viewModel.pendingAutoConnect = nil
                                    viewModel.connect(to: currentServer)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "terminal")
                                        Text(LocalizedStrings.startTerminal)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    // Entfernt: zusätzliche Sidebar-Toggle-Schaltfläche
                    .toolbar {
                        pendingToolbar(for: currentServer)
                    }
                } else {
                    VStack(spacing: 16) {
                        Spacer()
                        VStack(spacing: 12) {
                            Text(LocalizedStrings.connectionLost(currentServer.displayName))
                                .foregroundColor(.secondary)
                            Button {
                                viewModel.connect(to: currentServer)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text(LocalizedStrings.reconnect)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    // Entfernt: zusätzliche Sidebar-Toggle-Schaltfläche
                    .toolbar {
                        pendingToolbar(for: currentServer)
                    }
                }
            } else {
                // Server was deleted, return to overview
                VStack {
                    Text(LocalizedStrings.serverNotFound)
                        .foregroundColor(.secondary)
                    Button {
                        viewModel.selectedNavigationItem = .overview
                    } label: {
                        Text(LocalizedStrings.backToOverview)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.async {
                        viewModel.selectedNavigationItem = .overview
                    }
                }
            }
        }
    }

    // Toolbar für Pending/Recent-Zustände ohne aktiven Manager
    @ToolbarContentBuilder
    private func pendingToolbar(for server: Server) -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            TerminalToolbarTitleRow(
                displayName: server.displayName,
                connectionLine: "\(server.username)@\(server.host):\(server.port)",
                operatingSystem: server.operatingSystem
            )
        }

        ToolbarItem(placement: .principal) {
            Spacer()
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.pendingAutoConnect = nil
                viewModel.connect(to: server)
            } label: {
                Label(LocalizedStrings.connect, systemImage: "globe")
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, MainWindowToolbarInsets.terminalTitleHorizontal)
        }
    }
}

struct TerminalContainerViewInternal: View {
    let server: Server
    let viewModel: AppViewModel
    @ObservedObject var manager: ConnectionManager

    var body: some View {
        let content: some View = VStack(spacing: 0) {
            // Terminal content
            // Show connecting state or error, not terminal until connected
            if manager.isConnecting {
                // Show connecting state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(LocalizedStrings.connectingTo(server.displayName))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(server.username)@\(server.host):\(String(server.port))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        viewModel.disconnect(from: server)
                        viewModel.selectedNavigationItem = .overview
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text(LocalizedStrings.cancel)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.isConnected {
                // Only show terminal when actually connected
                TerminalViewWithHolder(server: server, viewModel: viewModel, manager: manager)
            } else if manager.connectionError != nil {
                // Show error message
                TerminalViewWithHolder(server: server, viewModel: viewModel, manager: manager)
            } else {
                // Fallback: show reconnect option
                VStack {
                    Text(LocalizedStrings.connectionLost(server.displayName))
                        .foregroundColor(.secondary)
                    Button {
                        viewModel.connect(to: server)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text(LocalizedStrings.reconnect)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        content
            .toolbar {
                terminalToolbar
            }
            .onChange(of: manager.connectionError) { newValue in
                guard let message = newValue else { return }
                presentConnectionErrorAlert(message: message)
            }
        // Entfernt: zusätzliche Sidebar-Toggle-Schaltfläche
    }

    private func presentConnectionErrorAlert(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.messageText = LocalizedStrings.connectionFailedTitle
        let hint = LocalizedStrings.connectionFailedHint
        let sanitizedMessage = message
            .replacingOccurrences(of: "•", with: "")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        alert.informativeText = sanitizedMessage.isEmpty ? hint : sanitizedMessage
        alert.addButton(withTitle: LocalizedStrings.reconnect)
        alert.addButton(withTitle: LocalizedStrings.close)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            manager.connectionError = nil
            viewModel.connect(to: server)
        } else {
            manager.connectionError = nil
        }
    }

    @ToolbarContentBuilder
    private var terminalToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            toolbarTitle
        }
        // Füllt den mittleren Bereich, damit die Aktionen wirklich rechts landen
        ToolbarItem(placement: .principal) {
            Spacer()
        }
        ToolbarItem(placement: .primaryAction) {
            toolbarActions
        }
    }

    private var toolbarTitle: some View {
        TerminalToolbarTitleRow(
            displayName: server.displayName,
            connectionLine: "\(server.username)@\(server.host):\(server.port)",
            operatingSystem: manager.detectedOS
        )
    }

    private var toolbarActions: some View {
        HStack(spacing: 10) {
            if manager.isConnected {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .padding(.trailing, 6)
                Button {
                    viewModel.disconnect(from: server)
                    viewModel.selectedNavigationItem = .overview
                } label: {
                    Label(LocalizedStrings.disconnect, systemImage: "stop.circle")
                        .labelStyle(.titleAndIcon)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            } else if manager.isConnecting {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
                    .padding(.trailing, 6)
                Button {
                    viewModel.disconnect(from: server)
                    viewModel.selectedNavigationItem = .overview
                } label: {
                    Text(LocalizedStrings.cancel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            } else {
                let hasError = manager.connectionError != nil
                Button {
                    manager.connectionError = nil
                    viewModel.connect(to: server)
                } label: {
                    Group {
                        if hasError {
                            Label(LocalizedStrings.reconnect, systemImage: "arrow.clockwise")
                        } else {
                            Label(LocalizedStrings.connect, systemImage: "globe")
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, MainWindowToolbarInsets.terminalTitleHorizontal)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct TerminalViewWithHolder: View {
    let server: Server
    let viewModel: AppViewModel
    @ObservedObject var manager: ConnectionManager

    var body: some View {
        let holder: TerminalHolder = {
            if let existingHolder = viewModel.terminalHolders[server.id] {
                return existingHolder
            } else {
                let newHolder = TerminalHolder()
                viewModel.terminalHolders[server.id] = newHolder
                return newHolder
            }
        }()

        // Show error message if connection failed
        if !manager.isConnecting && !manager.isConnected && manager.connectionError != nil {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text(LocalizedStrings.connectionFailedTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                if let error = manager.connectionError {
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Button {
                    viewModel.connect(to: server)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(LocalizedStrings.reconnect)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.windowBackgroundColor))
        } else {
            TerminalView(manager: manager, holder: holder)
        }
    }
}

// MARK: - Keys View

struct KeysView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode {
        case grid
        case list
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.keys.isEmpty {
                EmptyKeysView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(LocalizedStrings.keys)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 24)

                        if viewMode == .grid {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.keys) { key in
                                    KeyCardView(key: key, viewModel: viewModel)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.keys) { key in
                                    KeyListView(key: key, viewModel: viewModel)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Ensure grid view is active by default
            if viewMode != .grid {
                viewMode = .grid
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    // Grid/List toggle buttons grouped together
                    HStack(spacing: 4) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewMode = .grid
                            }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 28, height: 28)
                        .foregroundColor(viewMode == .grid ? .accentColor : .secondary)
                        .background(viewMode == .grid ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewMode = .list
                            }
                        } label: {
                            Image(systemName: "list.dash")
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 28, height: 28)
                        .foregroundColor(viewMode == .list ? .accentColor : .secondary)
                        .background(viewMode == .list ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                    }
                    
                    Button {
                        viewModel.showNewKeySheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, MainWindowToolbarInsets.horizontal)
            }
        }
        .sheet(isPresented: $viewModel.showNewKeySheet) {
            NewKeySheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.showEditKeySheet) { key in
            EditKeySheet(viewModel: viewModel, key: key)
        }
    }
}

struct EmptyKeysView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "key")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(LocalizedStrings.noKeys)
                .font(.title)
                .fontWeight(.semibold)
            
            Text(LocalizedStrings.savedKeysWillAppear)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Button {
                viewModel.showNewKeySheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(LocalizedStrings.newKey)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct KeyCardView: View {
    let key: SSHKey
    @ObservedObject var viewModel: AppViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                
                Text(key.name)
                    .font(.headline)
                
                Spacer()
            }
            
            (Text("\(LocalizedStrings.keyCreatedLabel): ") + Text(key.createdAt, style: .date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Spacer()
                
                // Edit button (icon)
                Button {
                    viewModel.showEditKeySheet = key
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                // Delete button (icon)
                Button {
                    viewModel.showDeleteKeyConfirmation = key
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .controlSize(.large)
            }
        }
        .padding(16)
        .frame(height: 140)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHovered
                        ? Color.accentColor.opacity(0.3)
                        : Color.gray.opacity(0.1),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .shadow(
            color: isHovered
                ? Color.black.opacity(0.15)
                : Color.black.opacity(0.1),
            radius: isHovered ? 3 : 2,
            x: 0,
            y: isHovered ? 2 : 1
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                viewModel.showEditKeySheet = key
            } label: {
                Label(LocalizedStrings.editKey, systemImage: "slider.horizontal.3")
            }
            
            Button {
                viewModel.showDeleteKeyConfirmation = key
            } label: {
                Label(LocalizedStrings.delete, systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

struct KeyListView: View {
    let key: SSHKey
    @ObservedObject var viewModel: AppViewModel
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(key.name)
                    .font(.headline)
                (Text("\(LocalizedStrings.keyCreatedLabel): ") + Text(key.createdAt, style: .date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit button (icon)
            Button {
                viewModel.showEditKeySheet = key
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            // Delete button (icon)
            Button {
                viewModel.showDeleteKeyConfirmation = key
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .controlSize(.large)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            isHovered
                ? Color(.windowBackgroundColor).opacity(0.8)
                : Color(.windowBackgroundColor)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isHovered
                        ? Color.accentColor.opacity(0.18)
                        : Color.gray.opacity(0.06),
                    lineWidth: isHovered ? 1.2 : 1
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                viewModel.showEditKeySheet = key
            } label: {
                Label(LocalizedStrings.editKey, systemImage: "slider.horizontal.3")
            }
            
            Button {
                viewModel.showDeleteKeyConfirmation = key
            } label: {
                Label(LocalizedStrings.delete, systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - New Key Sheet

struct NewKeySheet: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var keyName = ""
    @State private var privateKey = ""
    @State private var publicKey = ""
    @State private var keyType: KeyType = .ed25519
    
    var isValidForm: Bool {
        !keyName.isEmpty && !privateKey.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(LocalizedStrings.newKey)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Key Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStrings.keyName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("", text: $keyName)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Private Key (read-only)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(LocalizedStrings.privateKey)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !privateKey.isEmpty {
                                    Button {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(privateKey, forType: .string)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                            Text(LocalizedStrings.copy)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            if privateKey.isEmpty {
                                ScrollView {
                                    Text("")
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                }
                                .frame(height: 120)
                                .background(Color(.textBackgroundColor).opacity(0.5))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            } else {
                                ScrollView {
                                    Text(privateKey)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                }
                                .frame(height: 120)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Public Key (read-only, auto-generated)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(publicKey.isEmpty ? LocalizedStrings.publicKeyOptional : LocalizedStrings.publicKeyAutoGenerated)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !publicKey.isEmpty {
                                    Spacer()
                                    Button {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(publicKey, forType: .string)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                            Text(LocalizedStrings.copy)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            if publicKey.isEmpty {
                                TextEditor(text: .constant(""))
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color(.textBackgroundColor).opacity(0.5))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .disabled(true)
                            } else {
                                ScrollView {
                                    Text(publicKey)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                }
                                .frame(height: 80)
                                .background(Color(.textBackgroundColor).opacity(0.5))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Options: Generate or Import
                        VStack(alignment: .leading, spacing: 12) {
                            // Generate Option
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(LocalizedStrings.keyType)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Menu {
                                            ForEach(KeyType.allCases, id: \.self) { type in
                                                Button {
                                                    keyType = type
                                                } label: {
                                                    Text(type.rawValue)
                                                }
                                            }
                                        } label: {
                                            Text(keyType.rawValue)
                                                .font(.system(size: 13))
                                                .frame(maxWidth: 200, alignment: .leading)
                                                .frame(height: 24)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color(.textBackgroundColor))
                                                .cornerRadius(6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        generateKey()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.2.circlepath")
                                            Text(LocalizedStrings.generate)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            
                            Divider()
                            
                            // Import Option
                            Button {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = true
                                panel.canChooseDirectories = false
                                panel.allowsMultipleSelection = false
                                panel.begin { resp in
                                    guard resp == .OK, let url = panel.url else { return }
                                    do {
                                        let keyContent = try String(contentsOf: url, encoding: .utf8)
                                        privateKey = keyContent
                                        
                                        // Try to find corresponding public key
                                        let publicKeyURL = url.deletingLastPathComponent().appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".pub")
                                        if FileManager.default.fileExists(atPath: publicKeyURL.path) {
                                            publicKey = try String(contentsOf: publicKeyURL, encoding: .utf8)
                                        }
                                    } catch {
                                        print("Failed to read key file: \(error)")
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.doc")
                                    Text(LocalizedStrings.importKey)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Info Text
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text(LocalizedStrings.privateKeysEncrypted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !publicKey.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text(LocalizedStrings.publicKeyInstallHint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                        Text(LocalizedStrings.cancel)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    saveKey()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text(LocalizedStrings.save)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .disabled(!isValidForm)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 600, height: 700)
    }
    
    private func generateKey() {
        // Generate SSH key using ssh-keygen
        let tempDir = FileManager.default.temporaryDirectory
        let tempKeyFile = tempDir.appendingPathComponent("\(UUID().uuidString)_temp_key")
        let tempPubFile = tempKeyFile.appendingPathExtension("pub")
        
        // Determine key type argument for ssh-keygen
        let keyTypeArg: String
        switch keyType {
        case .ed25519:
            keyTypeArg = "ed25519"
        case .ecdsa256:
            keyTypeArg = "ecdsa"
        case .ecdsa384:
            keyTypeArg = "ecdsa"
        case .ecdsa521:
            keyTypeArg = "ecdsa"
        }
        
        // Additional arguments for ECDSA key sizes
        var keygenArgs = ["-t", keyTypeArg, "-f", tempKeyFile.path, "-N", "", "-C", ""]
        if keyType == .ecdsa256 {
            keygenArgs.append("-b")
            keygenArgs.append("256")
        } else if keyType == .ecdsa384 {
            keygenArgs.append("-b")
            keygenArgs.append("384")
        } else if keyType == .ecdsa521 {
            keygenArgs.append("-b")
            keygenArgs.append("521")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        process.arguments = keygenArgs
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                // Check if files exist
                let privateKeyExists = FileManager.default.fileExists(atPath: tempKeyFile.path)
                let publicKeyExists = FileManager.default.fileExists(atPath: tempPubFile.path)
                
                print("Private key file exists: \(privateKeyExists) at \(tempKeyFile.path)")
                print("Public key file exists: \(publicKeyExists) at \(tempPubFile.path)")
                
                // Read private key
                if privateKeyExists, let privateKeyContent = try? String(contentsOf: tempKeyFile, encoding: .utf8) {
                    privateKey = privateKeyContent
                    print("Private key read successfully, length: \(privateKeyContent.count) characters")
                } else {
                    privateKey = "Failed to read generated private key"
                    print("Failed to read private key from \(tempKeyFile.path)")
                }
                
                // Read public key - ssh-keygen should create .pub file automatically
                if publicKeyExists, let publicKeyContent = try? String(contentsOf: tempPubFile, encoding: .utf8) {
                    publicKey = publicKeyContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("Public key read successfully: \(publicKey.prefix(50))...")
                } else {
                    // If .pub file doesn't exist, try to generate it from private key
                    print("Public key file not found, attempting to extract from private key")
                    if privateKeyExists {
                        let extractProcess = Process()
                        extractProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
                        extractProcess.arguments = ["-y", "-f", tempKeyFile.path]
                        
                        let pipe = Pipe()
                        extractProcess.standardOutput = pipe
                        extractProcess.standardError = pipe
                        
                        try extractProcess.run()
                        extractProcess.waitUntilExit()
                        
                        if extractProcess.terminationStatus == 0 {
                            let data = pipe.fileHandleForReading.readDataToEndOfFile()
                            if let publicKeyContent = String(data: data, encoding: .utf8) {
                                publicKey = publicKeyContent.trimmingCharacters(in: .whitespacesAndNewlines)
                                print("Public key extracted successfully: \(publicKey.prefix(50))...")
                            } else {
                                publicKey = ""
                                print("Failed to convert public key data to string")
                            }
                        } else {
                            publicKey = ""
                            print("Failed to extract public key, error code: \(extractProcess.terminationStatus)")
                        }
                    } else {
                        publicKey = ""
                        print("Cannot extract public key: private key file doesn't exist")
                    }
                }
                
                // Clean up temporary files
                try? FileManager.default.removeItem(at: tempKeyFile)
                try? FileManager.default.removeItem(at: tempPubFile)
            } else {
                privateKey = LocalizedStrings.keyGenerationFailedExitCode(process.terminationStatus)
                publicKey = ""
                print("ssh-keygen failed with exit code: \(process.terminationStatus)")
            }
        } catch {
            privateKey = LocalizedStrings.keyGenerationFailed(error.localizedDescription)
            publicKey = ""
            print("Exception during key generation: \(error)")
        }
    }
    
    private func saveKey() {
        let newKey = SSHKey(
            name: keyName,
            privateKey: privateKey,
            publicKey: publicKey.isEmpty ? nil : publicKey
        )
        viewModel.addKey(newKey)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Key Sheet

struct EditKeySheet: View {
    @ObservedObject var viewModel: AppViewModel
    let key: SSHKey
    @Environment(\.presentationMode) var presentationMode
    
    @State private var keyName = ""
    @State private var privateKey = ""
    @State private var publicKey = ""
    
    var isValidForm: Bool {
        !keyName.isEmpty && !privateKey.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(LocalizedStrings.editKey)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Key Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStrings.keyName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("", text: $keyName)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        // Private Key (read-only)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(LocalizedStrings.privateKey)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !privateKey.isEmpty {
                                    Button {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(privateKey, forType: .string)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                            Text(LocalizedStrings.copy)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            if privateKey.isEmpty {
                                ScrollView {
                                    Text("")
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                }
                                .frame(height: 120)
                                .background(Color(.textBackgroundColor).opacity(0.5))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            } else {
                                ScrollView {
                                    Text(privateKey)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                }
                                .frame(height: 120)
                                .background(Color(.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Public Key (read-only)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(publicKey.isEmpty ? LocalizedStrings.publicKeyOptional : LocalizedStrings.publicKeyAutoGenerated)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !publicKey.isEmpty {
                                    Button {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(publicKey, forType: .string)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                            Text(LocalizedStrings.copy)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            if publicKey.isEmpty {
                                TextEditor(text: .constant(""))
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color(.textBackgroundColor).opacity(0.5))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .disabled(true)
                            } else {
                                ScrollView {
                                    Text(publicKey)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                }
                                .frame(height: 80)
                                .background(Color(.textBackgroundColor).opacity(0.5))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Import Option
                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowsMultipleSelection = false
                            panel.begin { resp in
                                guard resp == .OK, let url = panel.url else { return }
                                do {
                                    let keyContent = try String(contentsOf: url, encoding: .utf8)
                                    privateKey = keyContent
                                    
                                    // Try to find corresponding public key
                                    let publicKeyURL = url.deletingLastPathComponent().appendingPathComponent(url.deletingPathExtension().lastPathComponent + ".pub")
                                    if FileManager.default.fileExists(atPath: publicKeyURL.path) {
                                        publicKey = try String(contentsOf: publicKeyURL, encoding: .utf8)
                                    }
                                } catch {
                                    print("Failed to read key file: \(error)")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.doc")
                                Text(LocalizedStrings.importKey)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        
                        // Info Text
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text(LocalizedStrings.privateKeysEncrypted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                        Text(LocalizedStrings.cancel)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    saveKey()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                        Text(LocalizedStrings.save)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .disabled(!isValidForm)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 600, height: 700)
        .onAppear {
            keyName = key.name
            // Key is already decrypted in memory (from loadKeys())
            privateKey = key.privateKey
            // Public key is also already decrypted if available
            publicKey = key.publicKey ?? ""
        }
    }
    
    private func extractPublicKey() {
        guard !privateKey.isEmpty else { return }
        
        // Save private key to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempKeyFile = tempDir.appendingPathComponent("\(UUID().uuidString)_extract_key")
        
        do {
            // Write private key to temporary file
            try privateKey.write(to: tempKeyFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: tempKeyFile.path)
            
            // Extract public key using ssh-keygen
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
            process.arguments = ["-y", "-f", tempKeyFile.path]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let publicKeyContent = String(data: data, encoding: .utf8) {
                    publicKey = publicKeyContent.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    print("Failed to convert public key data to string")
                }
            } else {
                print("Failed to extract public key, error code: \(process.terminationStatus)")
            }
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempKeyFile)
        } catch {
            print("Failed to extract public key: \(error)")
        }
    }
    
    private func saveKey() {
        var updatedKey = key
        updatedKey.name = keyName
        updatedKey.privateKey = privateKey
        updatedKey.publicKey = publicKey.isEmpty ? nil : publicKey
        viewModel.updateKey(updatedKey)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Settings View

enum SettingsCategory: String, CaseIterable, Identifiable {
    case terminal = "terminal"
    case sessions = "sessions"
    case connection = "connection"
    case general = "general"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .terminal:
            return LocalizedStrings.terminalSettings
        case .sessions:
            return LocalizedStrings.sessionSettings
        case .connection:
            return LocalizedStrings.connectionSettings
        case .general:
            return LocalizedStrings.generalSettings
        }
    }

    var icon: String {
        switch self {
        case .terminal:
            return "terminal"
        case .sessions:
            return "rectangle.stack"
        case .connection:
            return "bolt.horizontal.circle"
        case .general:
            return "sidebar.left"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // (Header entfernt — Fenster hat eigenen Titelbar)

            // Main Content mit hellerem Background
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Allgemein Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.generalSettings)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            // Launch at Login
                            SettingRow(label: LocalizedStrings.launchAtLogin, description: LocalizedStrings.launchAtLoginDescription) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.launchAtLogin)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }

                            SettingDivider()

                            // Show Notifications
                            SettingRow(label: LocalizedStrings.showNotifications, description: LocalizedStrings.showNotificationsDescription) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.showNotifications)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }

                    SettingDivider()

                    // Language Selection
                    SettingRow(label: LocalizedStrings.language, description: LocalizedStrings.languageDescription) {
                        Picker("", selection: $settings.appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }
                    
                    // View Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.viewSettings)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 0) {
                            SettingRow(label: LocalizedStrings.showStatusBar) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.showStatusBar)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }
                            
                            SettingDivider()
                            
                            SettingRow(label: LocalizedStrings.showSidebar) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.showSidebar)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Terminal Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.terminalSettings)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            // Terminal Theme
                            SettingRow(label: LocalizedStrings.terminalTheme) {
                                Picker("", selection: $settings.terminalTheme) {
                                    ForEach(TerminalTheme.allCases, id: \.self) { theme in
                                        Text(theme.displayName).tag(theme)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }

                            SettingDivider()

                            // Font Family
                            SettingRow(label: LocalizedStrings.fontFamily) {
                                Picker("", selection: $settings.terminalFontFamily) {
                                    ForEach(TerminalFontFamily.allCases, id: \.self) { font in
                                        Text(font.displayName).tag(font)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            SettingDivider()

                            // Cursor Style
                            SettingRow(label: LocalizedStrings.cursorStyle) {
                                Picker("", selection: $settings.terminalCursorStyle) {
                                    ForEach(TerminalCursorStyle.allCases, id: \.self) { style in
                                        Text(style.displayName).tag(style)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            SettingDivider()

                            // Font Size
                            SettingRow(label: LocalizedStrings.fontSize, description: LocalizedStrings.fontSizeDescription) {
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(settings.terminalFontSize) },
                                        set: { settings.terminalFontSize = Int($0) }
                                    ), in: 8...24, step: 1, label: {})
                                        .frame(maxWidth: .infinity)
                                    Text("\(settings.terminalFontSize) pt")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                            }

                            SettingDivider()

                            // Scroll Buffer Size
                            SettingRow(label: LocalizedStrings.scrollBufferSize, description: LocalizedStrings.scrollBufferDescription) {
                                TextField("", text: Binding(
                                    get: { String(settings.terminalScrollBufferSize) },
                                    set: {
                                        if let value = Int($0) {
                                            settings.terminalScrollBufferSize = max(100, min(10000, value))
                                        }
                                    }
                                ))
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.textBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            SettingDivider()

                            // Keep Display Active
                            SettingRow(label: LocalizedStrings.keepDisplayActive, description: LocalizedStrings.keepDisplayDescription) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.terminalKeepDisplayActive)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Sitzungen Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.sessionSettings)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            // Detect Operating System
                            SettingRow(label: LocalizedStrings.detectOperatingSystem, description: LocalizedStrings.detectOSDescription) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.detectOperatingSystem)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }

                            SettingDivider()

                            // Keep Sessions Alive
                            SettingRow(label: LocalizedStrings.keepSessionsAlive, description: LocalizedStrings.keepAliveDescription) {
                                HStack {
                                    Spacer()
                                    Toggle("", isOn: $settings.keepSessionsAlive)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.mini)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }

                    // Verbindung Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStrings.connectionSettings)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            // Connection Timeout
                            SettingRow(label: LocalizedStrings.connectionTimeout, description: LocalizedStrings.connectionTimeoutDescription) {
                                TextField("", text: Binding(
                                    get: { String(settings.connectionTimeout) },
                                    set: {
                                        if let value = Int($0) {
                                            settings.connectionTimeout = max(5, min(60, value))
                                        }
                                    }
                                ))
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.textBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            SettingDivider()

                            // Default Port
                            SettingRow(label: LocalizedStrings.defaultPort, description: LocalizedStrings.defaultPortDescription) {
                                TextField("", text: Binding(
                                    get: { String(settings.defaultPort) },
                                    set: {
                                        if let value = Int($0) {
                                            settings.defaultPort = value
                                        }
                                    }
                                ))
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.textBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(.windowBackgroundColor).opacity(0.8)) // Hellerer Content Background
        }
        .frame(width: 700, height: 550)
        .background(Color(.windowBackgroundColor))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// Hilfs-Views für die Settings
struct SettingRow<Content: View>: View {
    let label: String
    let descriptionText: String?
    let content: Content

    init(label: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.descriptionText = description
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                if let desc = descriptionText, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 160, alignment: .leading)

            // Control area - vertically centered
            HStack {
                content
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 14)
        .frame(minHeight: 44)
    }
}

struct SettingDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }
}

// MARK: - Terminal Settings Section

struct TerminalSettingsSection: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(LocalizedStrings.terminalSettings)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 20) {
                // Terminal Theme
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.terminalTheme)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Picker("", selection: $settings.terminalTheme) {
                        ForEach(TerminalTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }

                // Font Family
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.fontFamily)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach(TerminalFontFamily.allCases, id: \.self) { font in
                            Button {
                                settings.terminalFontFamily = font
                            } label: {
                                Text(font.displayName)
                            }
                        }
                    } label: {
                        HStack {
                            Text(settings.terminalFontFamily.displayName)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                // Cursor Style
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.cursorStyle)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach(TerminalCursorStyle.allCases, id: \.self) { style in
                            Button {
                                settings.terminalCursorStyle = style
                            } label: {
                                Text(style.displayName)
                            }
                        }
                    } label: {
                        HStack {
                            Text(settings.terminalCursorStyle.displayName)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.fontSize)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        Slider(value: Binding(
                            get: { Double(settings.terminalFontSize) },
                            set: { settings.terminalFontSize = Int($0) }
                        ), in: 8...24, step: 1, label: {})
                            .frame(maxWidth: .infinity)
                        Text("\(settings.terminalFontSize) pt")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }

                // Scroll Buffer Size
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.scrollBufferSize)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    TextField("", text: Binding(
                        get: { String(settings.terminalScrollBufferSize) },
                        set: {
                            if let value = Int($0) {
                                settings.terminalScrollBufferSize = max(100, min(10000, value))
                            }
                        }
                    ))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                // Keep Display Active
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStrings.keepDisplayActive)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: $settings.terminalKeepDisplayActive)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// MARK: - Session Settings Section

struct SessionSettingsSection: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(LocalizedStrings.sessionSettings)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 20) {
                // Detect Operating System
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.detectOperatingSystem)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.detectOSDescription)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    HStack {
                        Spacer()
                        Toggle("", isOn: $settings.detectOperatingSystem)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }

                // Keep Sessions Alive
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.keepSessionsAlive)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.keepAliveDescription)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    HStack {
                        Spacer()
                        Toggle("", isOn: $settings.keepSessionsAlive)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Connection Settings Section

struct ConnectionSettingsSection: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(LocalizedStrings.connectionSettings)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 20) {
                // Connection Timeout
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.connectionTimeout)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    TextField("", text: Binding(
                        get: { String(settings.connectionTimeout) },
                        set: {
                            if let value = Int($0) {
                                settings.connectionTimeout = max(5, min(60, value))
                            }
                        }
                    ))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                // Default Port
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.defaultPort)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    TextField("", text: Binding(
                        get: { String(settings.defaultPort) },
                        set: {
                            if let value = Int($0) {
                                settings.defaultPort = value
                            }
                        }
                    ))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - General Settings Section

struct GeneralSettingsSection: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(LocalizedStrings.generalSettings)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 20) {
                // Launch at Login
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.launchAtLogin)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.launchAtLoginDescription)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    HStack {
                        Spacer()
                        Toggle("", isOn: $settings.launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }

                // Show Notifications
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.showNotifications)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.showNotificationsDescription)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    HStack {
                        Spacer()
                        Toggle("", isOn: $settings.showNotifications)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }

                // Language Selection
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.language)
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.languageDescription)
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    Picker("", selection: $settings.appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppViewModel())
    }
}




