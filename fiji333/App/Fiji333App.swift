import SwiftUI

// TrollOS: a pretend operating system. Nothing here touches the real device.

@main
struct Fiji333App: App {
    @StateObject private var os = OSState()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(os)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

// MARK: - System

enum Phase { case off, boot, lock, home }

enum AppID: String, CaseIterable, Identifiable {
    case settings = "Settings"
    case terminal = "Terminal"
    case files = "Files"
    case notes = "Notes"
    case calc = "Calc"
    case clock = "Clock"
    case store = "Store"
    case jail = "fiji333"
    case game = "TapTroll"
    case paint = "Paint"
    case browser = "Web"
    case about = "About"

    var id: String { rawValue }

    var tile: String {
        switch self {
        case .settings: return "SET"
        case .terminal: return ">_"
        case .files: return "DIR"
        case .notes: return "TXT"
        case .calc: return "+-"
        case .clock: return "12:00"
        case .store: return "GET"
        case .jail: return "333"
        case .game: return "TAP"
        case .paint: return "ART"
        case .browser: return "WWW"
        case .about: return "?"
        }
    }

    var color: Color {
        switch self {
        case .settings: return .gray
        case .terminal: return .black
        case .files: return .blue
        case .notes: return .yellow
        case .calc: return .orange
        case .clock: return .indigo
        case .store: return .purple
        case .jail: return .teal
        case .game: return .red
        case .paint: return .pink
        case .browser: return .cyan
        case .about: return .brown
        }
    }
}

@MainActor
final class OSState: ObservableObject {
    @Published var phase: Phase = .boot
    @Published var openApp: AppID?
    @Published var installed: Set<String> = []
    @Published var jailbroken = false
    @Published var popupTitle = ""
    @Published var popupText = ""
    @Published var showPopup = false
    @AppStorage("wallpaper") var wallpaper = 0
    @AppStorage("username") var username = "troll"

    static let wallpapers: [[Color]] = [
        [.blue, .purple], [.teal, .green], [.orange, .pink], [.black, .gray]
    ]

    var gradient: LinearGradient {
        let list = Self.wallpapers
        return LinearGradient(colors: list[wallpaper % list.count],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    func popup(_ title: String, _ text: String) {
        popupTitle = title
        popupText = text
        showPopup = true
    }

    func reboot() {
        openApp = nil
        phase = .boot
    }

    func shutdown() {
        openApp = nil
        phase = .off
    }

    func wipe() {
        installed = []
        jailbroken = false
        wallpaper = 0
        username = "troll"
        reboot()
    }
}

struct RootView: View {
    @EnvironmentObject var os: OSState

    var body: some View {
        ZStack {
            switch os.phase {
            case .off: OffView()
            case .boot: BootView()
            case .lock: LockView()
            case .home: DesktopView()
            }
        }
        .preferredColorScheme(.dark)
        .alert(os.popupTitle, isPresented: $os.showPopup) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(os.popupText)
        }
    }
}

struct OffView: View {
    @EnvironmentObject var os: OSState
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Button("Power On") { os.phase = .boot }
                .buttonStyle(.bordered)
        }
    }
}

struct BootView: View {
    @EnvironmentObject var os: OSState
    @State private var progress = 0.0
    @State private var line = "Starting emulator..."

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("TrollOS")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                ProgressView(value: progress).frame(width: 220).tint(.white)
                Text(line).font(.system(.footnote, design: .monospaced)).foregroundColor(.green)
                Text("Fake emulator, just for fun").font(.caption).foregroundColor(.gray)
            }
        }
        .task {
            let steps = ["Loading fake kernel", "Mounting banana drive",
                         "Starting TrollBoard", "Feeding the hamsters", "Welcome"]
            for (i, step) in steps.enumerated() {
                line = step
                withAnimation { progress = Double(i + 1) / Double(steps.count) }
                try? await Task.sleep(nanoseconds: 700_000_000)
                if Task.isCancelled { return }
            }
            os.phase = .lock
        }
    }
}

struct LockView: View {
    @EnvironmentObject var os: OSState
    var body: some View {
        ZStack {
            os.gradient.ignoresSafeArea()
            VStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack {
                        Text(context.date, format: .dateTime.hour().minute())
                            .font(.system(size: 72, weight: .thin))
                        Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    }
                }
                .padding(.top, 60)
                Spacer()
                Text("Hello, \(os.username)").font(.title2)
                Button { os.phase = .home } label: {
                    Text("Unlock")
                        .bold()
                        .frame(width: 200, height: 50)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 40)
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - Home screen

struct AppTile: View {
    let app: AppID
    var size: CGFloat = 62
    var body: some View {
        Text(app.tile)
            .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(app.color)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
    }
}

struct DesktopView: View {
    @EnvironmentObject var os: OSState
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    private let dock: [AppID] = [.terminal, .files, .browser, .settings]

    var body: some View {
        ZStack {
            os.gradient.ignoresSafeArea()
            VStack {
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(AppID.allCases.filter { !dock.contains($0) }) { app in
                        icon(app, label: true)
                    }
                }
                .padding(.top, 24)
                Spacer()
                if !os.installed.isEmpty {
                    Text("Installed: \(os.installed.sorted().joined(separator: ", "))")
                        .font(.caption)
                }
                HStack {
                    ForEach(dock) { app in
                        icon(app, label: false).frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            if let app = os.openApp {
                AppWindow(app: app)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .foregroundColor(.white)
    }

    private func icon(_ app: AppID, label: Bool) -> some View {
        Button {
            withAnimation(.spring()) { os.openApp = app }
        } label: {
            VStack(spacing: 6) {
                AppTile(app: app)
                if label { Text(app.rawValue).font(.caption).foregroundColor(.white) }
            }
        }
    }
}

struct AppWindow: View {
    @EnvironmentObject var os: OSState
    let app: AppID

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Home") { withAnimation { os.openApp = nil } }
                Spacer()
                Text(app.rawValue).bold()
                Spacer()
                Text("Home").hidden()
            }
            .padding()
            .background(Color(white: 0.1))
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
    }

    @ViewBuilder private var content: some View {
        switch app {
        case .settings: SettingsApp()
        case .terminal: TerminalApp()
        case .files: FilesApp()
        case .notes: NotesApp()
        case .calc: CalcApp()
        case .clock: ClockApp()
        case .store: StoreApp()
        case .jail: JailApp()
        case .game: GameApp()
        case .paint: PaintApp()
        case .browser: BrowserApp()
        case .about: AboutApp()
        }
    }
}

// MARK: - Apps

struct Row: View {
    let tile: String
    let color: Color
    let title: String
    var value: String = ""
    var body: some View {
        HStack(spacing: 12) {
            Text(tile)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title).foregroundColor(.primary)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

struct SettingsApp: View {
    @EnvironmentObject var os: OSState
    @State private var wifi = true
    @State private var blue = false
    @State private var turbo = false
    @State private var confirmWipe = false

    var body: some View {
        List {
            Section("User") {
                TextField("Username", text: $os.username)
            }
            Section("Pretend switches") {
                Toggle(isOn: $wifi) { Row(tile: "WF", color: .blue, title: "Troll-Fi") }
                Toggle(isOn: $blue) { Row(tile: "BT", color: .indigo, title: "Bluetroll") }
                Toggle(isOn: $turbo) { Row(tile: "TB", color: .red, title: "Turbo Mode") }
            }
            Section("Wallpaper") {
                Picker("Wallpaper", selection: $os.wallpaper) {
                    Text("Ocean").tag(0)
                    Text("Jungle").tag(1)
                    Text("Sunset").tag(2)
                    Text("Night").tag(3)
                }
                .pickerStyle(.segmented)
            }
            Section("Power") {
                Button { os.phase = .lock; os.openApp = nil } label: {
                    Row(tile: "LK", color: .gray, title: "Lock")
                }
                Button { os.reboot() } label: { Row(tile: "RB", color: .orange, title: "Reboot") }
                Button { os.shutdown() } label: { Row(tile: "OFF", color: .red, title: "Shut Down") }
                Button { confirmWipe = true } label: {
                    Row(tile: "X", color: .pink, title: "Reset TrollOS")
                }
            }
        }
        .alert("Reset TrollOS?", isPresented: $confirmWipe) {
            Button("Reset", role: .destructive) { os.wipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Only resets this pretend system.")
        }
    }
}

struct TerminalApp: View {
    @EnvironmentObject var os: OSState
    @State private var input = ""
    @State private var lines = ["TrollOS shell. Type help"]

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text(lines.joined(separator: "\n"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Text("$")
                TextField("command", text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(run)
                Button("Run", action: run)
            }
        }
        .font(.system(.footnote, design: .monospaced))
        .foregroundColor(.green)
        .padding()
    }

    private func run() {
        let cmd = input.trimmingCharacters(in: .whitespaces).lowercased()
        input = ""
        if cmd.isEmpty { return }
        if cmd == "clear" { lines = []; return }
        if cmd == "reboot" { os.reboot(); return }
        lines.append("$ " + cmd)
        switch cmd {
        case "help": lines.append("help ls whoami date ver troll neofetch reboot clear")
        case "ls": lines.append("Bananas/  Memes/  System/  readme.txt")
        case "whoami": lines.append(os.username)
        case "date": lines.append(Date().formatted())
        case "ver": lines.append("TrollOS 3.33 (pretend)")
        case "troll": lines.append("u mad? :)")
        case "neofetch": lines.append("OS: TrollOS\nKernel: banana-3.33\nRAM: 333 coconuts")
        default: lines.append("\(cmd): not found")
        }
    }
}

struct FilesApp: View {
    @EnvironmentObject var os: OSState
    private let folders: [(String, [String])] = [
        ("Bananas", ["ripe.txt", "green.txt"]),
        ("Memes", ["troll.meme", "classic.meme"]),
        ("System", ["kernel.fake", "boot.pretend"])
    ]

    var body: some View {
        List {
            ForEach(folders, id: \.0) { folder in
                Section(folder.0) {
                    ForEach(folder.1, id: \.self) { file in
                        Button {
                            os.popup(file, "This is a pretend file in \(folder.0).")
                        } label: {
                            Row(tile: "F", color: .blue, title: file)
                        }
                    }
                }
            }
        }
    }
}

struct NotesApp: View {
    @AppStorage("note") private var note = "Write something..."
    var body: some View {
        TextEditor(text: $note).padding()
    }
}

struct CalcApp: View {
    @State private var display = "0"
    @State private var stored = 0.0
    @State private var op = ""
    @State private var fresh = true
    private let keys = [["7", "8", "9", "/"], ["4", "5", "6", "x"],
                        ["1", "2", "3", "-"], ["C", "0", "=", "+"]]

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text(display)
                .font(.system(size: 54, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button { press(key) } label: {
                            Text(key)
                                .font(.title)
                                .frame(maxWidth: .infinity, minHeight: 70)
                                .background(Int(key) == nil ? Color.orange : Color(white: 0.2))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func press(_ key: String) {
        if Int(key) != nil {
            if fresh { display = key; fresh = false }
            else if display.count < 12 { display += key }
        } else if key == "C" {
            display = "0"; stored = 0; op = ""; fresh = true
        } else {
            let current = Double(display) ?? 0
            if !op.isEmpty && !fresh {
                var result = current
                if op == "+" { result = stored + current }
                if op == "-" { result = stored - current }
                if op == "x" { result = stored * current }
                if op == "/" { result = current == 0 ? 0 : stored / current }
                display = String(format: "%g", result)
                stored = result
            } else {
                stored = current
            }
            op = key == "=" ? "" : key
            fresh = true
        }
    }
}

struct ClockApp: View {
    @State private var start: Date?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            VStack(spacing: 30) {
                Text(context.date, format: .dateTime.hour().minute().second())
                    .font(.system(size: 44, design: .monospaced))
                Text(elapsed(context.date))
                    .font(.system(size: 34, design: .monospaced))
                    .foregroundColor(.orange)
                Button(start == nil ? "Start Stopwatch" : "Reset") {
                    start = start == nil ? Date() : nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func elapsed(_ now: Date) -> String {
        guard let start = start else { return "0.0 s" }
        return String(format: "%.1f s", max(0, now.timeIntervalSince(start)))
    }
}

struct StoreApp: View {
    @EnvironmentObject var os: OSState
    private let items = ["BananaTheme", "TrollKeyboard", "CocoWidgets", "MemePlayer", "WaveDock"]

    var body: some View {
        List(items, id: \.self) { item in
            Button {
                if os.installed.contains(item) {
                    os.installed.remove(item)
                    os.popup("Removed", "\(item) was removed.")
                } else {
                    os.installed.insert(item)
                    os.popup("Installed", "\(item) is pretend installed.")
                }
            } label: {
                Row(tile: String(item.prefix(2)), color: .purple, title: item,
                    value: os.installed.contains(item) ? "Remove" : "Get")
            }
        }
    }
}

struct JailApp: View {
    @EnvironmentObject var os: OSState
    @State private var progress = 0.0
    @State private var running = false

    var body: some View {
        VStack(spacing: 24) {
            AppTile(app: .jail, size: 100)
            Text(os.jailbroken ? "TrollOS is pretend jailbroken" : "TrollOS is locked")
            ProgressView(value: os.jailbroken ? 1 : progress).padding(.horizontal, 40)
            Button(running ? "Working..." : "Jailbreak") { running = true }
                .buttonStyle(.borderedProminent)
                .disabled(running || os.jailbroken)
            Text("Simulation only").font(.caption).foregroundColor(.gray)
        }
        .task(id: running) {
            guard running else { return }
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if Task.isCancelled { return }
                progress = Double(i) / 20
            }
            running = false
            os.jailbroken = true
            os.popup("Done", "Pretend jailbreak complete. Nothing real changed.")
        }
    }
}

struct GameApp: View {
    @AppStorage("best") private var best = 0
    @State private var score = 0
    @State private var spot = CGPoint(x: 0.5, y: 0.5)

    var body: some View {
        VStack {
            Text("Score \(score)   Best \(best)").font(.headline).padding()
            GeometryReader { geo in
                Button {
                    score += 1
                    best = max(best, score)
                    spot = CGPoint(x: Double.random(in: 0.15...0.85), y: Double.random(in: 0.1...0.9))
                } label: {
                    AppTile(app: .game, size: 70)
                }
                .position(x: geo.size.width * spot.x, y: geo.size.height * spot.y)
            }
            Button("Restart") { score = 0 }.padding()
        }
    }
}

struct PaintApp: View {
    @State private var cells = Array(repeating: Color(white: 0.15), count: 100)
    @State private var brush = Color.red
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .white]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 10)

    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<100, id: \.self) { i in
                    Rectangle()
                        .fill(cells[i])
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture { cells[i] = brush }
                }
            }
            HStack {
                ForEach(colors, id: \.self) { color in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 36, height: brush == color ? 52 : 36)
                        .onTapGesture { brush = color }
                }
            }
            Button("Clear") { cells = Array(repeating: Color(white: 0.15), count: 100) }
        }
        .padding()
    }
}

struct BrowserApp: View {
    @State private var address = "troll://home"
    @State private var page = "troll://home"

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                TextField("Address", text: $address)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { page = address }
                Button("Go") { page = address }
            }
            Text("TrollNet").font(.largeTitle).bold()
            Text(page == "troll://home" ? "Welcome to the pretend internet."
                 : "404: \(page) was eaten by a troll.")
                .multilineTextAlignment(.center)
            Button("Home Page") { address = "troll://home"; page = address }
            Spacer()
        }
        .padding()
    }
}

struct AboutApp: View {
    @EnvironmentObject var os: OSState
    var body: some View {
        List {
            Row(tile: "OS", color: .teal, title: "System", value: "TrollOS 3.33")
            Row(tile: "US", color: .blue, title: "User", value: os.username)
            Row(tile: "PK", color: .purple, title: "Packages", value: "\(os.installed.count)")
            Row(tile: "ME", color: .orange, title: "Made by", value: "You")
            Text("TrollOS is a fake emulator made for fun. It does not change your device.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
