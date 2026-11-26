import SwiftUI

// TrollOS runs entirely inside this app.

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
    @Published var banner: Banner?
    @Published var showControls = false
    @Published var brightness = 1.0
    @AppStorage("airplane") var airplane = false
    @AppStorage("wifi") var wifi = true
    @AppStorage("bluetooth") var bluetooth = true
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

    func notify(_ title: String, _ text: String) {
        let item = Banner(title: title, text: text)
        withAnimation(.spring()) { banner = item }
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if banner?.id == item.id { withAnimation { banner = nil } }
        }
    }

    func popup(_ title: String, _ text: String) {
        popupTitle = title
        popupText = text
        showPopup = true
    }

    func reboot() {
        openApp = nil
        showControls = false
        banner = nil
        phase = .boot
    }

    func shutdown() {
        openApp = nil
        showControls = false
        banner = nil
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

struct Banner: Identifiable {
    let id = UUID()
    let title: String
    let text: String
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
            Color.black
                .opacity((1 - os.brightness) * 0.7)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            if let banner = os.banner {
                VStack {
                    BannerView(banner: banner)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
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

struct BannerView: View {
    @EnvironmentObject var os: OSState
    let banner: Banner
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.green)
                .frame(width: 38, height: 38)
                .overlay(Text("T").bold())
            VStack(alignment: .leading) {
                Text(banner.title).bold()
                Text(banner.text).font(.subheadline)
            }
            Spacer()
            Text("now").font(.caption).foregroundColor(.secondary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 10)
        .onTapGesture { withAnimation { os.banner = nil } }
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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("TrollOS")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                ProgressView(value: progress).frame(width: 180).tint(.white)
            }
        }
        .task {
            for i in 1...40 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                if Task.isCancelled { return }
                progress = Double(i) / 40
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
                Text("Swipe up to unlock").font(.headline)
                Capsule().frame(width: 140, height: 5).padding(.bottom, 10)
            }
            .foregroundColor(.white)
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 30).onEnded { drag in
            if drag.translation.height < -60 {
                withAnimation { os.phase = .home }
                os.notify("Software Update", "TrollOS 3.4 is available in Settings.")
            }
        })
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

    @State private var search = ""

    private var visible: [AppID] {
        if search.isEmpty { return AppID.allCases.filter { !dock.contains($0) } }
        return AppID.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ZStack {
            os.gradient.ignoresSafeArea()
            VStack {
                HStack {
                    TextField("Search", text: $search)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Button("Controls") { withAnimation { os.showControls = true } }
                        .font(.subheadline.bold())
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(visible) { app in
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
            .foregroundColor(.white)
            if let app = os.openApp {
                AppWindow(app: app)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
            if os.showControls {
                ControlCentre()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
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

struct ControlCentre: View {
    @EnvironmentObject var os: OSState
    @State private var torch = false
    @State private var volume = 0.5

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { os.showControls = false } }
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    tile("Airplane", on: os.airplane, color: .orange) { os.airplane.toggle() }
                    tile("Wi-Fi", on: os.wifi && !os.airplane, color: .blue) { os.wifi.toggle() }
                }
                HStack(spacing: 14) {
                    tile("Bluetooth", on: os.bluetooth && !os.airplane, color: .blue) { os.bluetooth.toggle() }
                    tile("Torch", on: torch, color: .yellow) { torch.toggle() }
                }
                VStack(alignment: .leading) {
                    Text("Brightness")
                    Slider(value: $os.brightness, in: 0.2...1)
                    Text("Volume")
                    Slider(value: $volume)
                }
                .padding()
                .background(Color.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                Button("Done") { withAnimation { os.showControls = false } }
                    .buttonStyle(.borderedProminent)
            }
            .padding(30)
        }
    }

    private func tile(_ title: String, on: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Text(title).bold()
                Text(on ? "On" : "Off").font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(on ? color : Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct AppWindow: View {
    @EnvironmentObject var os: OSState
    let app: AppID

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
                Capsule()
                    .fill(Color.white)
                    .frame(width: 140, height: 5)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .contentShape(Rectangle())
                    .onTapGesture { close() }
                    .gesture(DragGesture(minimumDistance: 10).onEnded { drag in
                        if drag.translation.height < 0 { close() }
                    })
            }
            .navigationTitle(app.rawValue)
            .navigationBarTitleDisplayMode(app == .settings ? .large : .inline)
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func close() {
        withAnimation(.spring()) { os.openApp = nil }
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
    @State private var search = ""

    var body: some View {
        List {
            Section {
                NavigationLink { ProfilePage() } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 56, height: 56)
                            .overlay(Text(String(os.username.prefix(1)).uppercased()).font(.title2.bold()))
                        VStack(alignment: .leading) {
                            Text(os.username).font(.title3)
                            Text("Local profile").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Section {
                Toggle(isOn: $os.airplane) { Row(tile: "AIR", color: .orange, title: "Airplane Mode") }
                NavigationLink { WiFiPage() } label: {
                    Row(tile: "WF", color: .blue, title: "Wi-Fi",
                        value: os.wifi && !os.airplane ? "TrollNet" : "Off")
                }
                Toggle(isOn: $os.bluetooth) { Row(tile: "BT", color: .blue, title: "Bluetooth") }
            }
            Section {
                link("NO", .red, "Notifications") {
                    SwitchPage(title: "Notifications", names: ["Allow Notifications", "Sounds", "Badges", "Show Previews"])
                }
                link("SN", .pink, "Sounds & Haptics") {
                    SwitchPage(title: "Sounds & Haptics", names: ["Keyboard Clicks", "Lock Sound", "System Haptics"])
                }
                link("FO", .indigo, "Focus") {
                    SwitchPage(title: "Focus", names: ["Do Not Disturb", "Sleep", "Work"])
                }
            }
            Section {
                link("GN", .gray, "General") { GeneralPage() }
                link("DS", .blue, "Display & Brightness") { DisplayPage() }
                link("WP", .teal, "Wallpaper") { WallpaperPage() }
                link("BAT", .green, "Battery") { BatteryPage() }
                link("PR", .blue, "Privacy & Security") {
                    SwitchPage(title: "Privacy & Security", names: ["Location Services", "Tracking Requests", "Analytics"])
                }
            }
        }
        .searchable(text: $search)
        .onSubmit(of: .search) {
            os.popup("Search", "No results for \"\(search)\".")
        }
    }

    private func link<V: View>(_ tile: String, _ color: Color, _ title: String,
                               @ViewBuilder page: @escaping () -> V) -> some View {
        NavigationLink { page() } label: { Row(tile: tile, color: color, title: title) }
    }
}

struct ProfilePage: View {
    @EnvironmentObject var os: OSState
    var body: some View {
        List {
            Section("Name") { TextField("Name", text: $os.username) }
        }
        .navigationTitle("Profile")
    }
}

struct WiFiPage: View {
    @EnvironmentObject var os: OSState
    @State private var chosen = ""
    @State private var asking = false
    private let networks = ["TrollNet", "Coconut-5G", "FBI Van", "Free Bananas"]

    var body: some View {
        List {
            Toggle("Wi-Fi", isOn: $os.wifi)
            if os.wifi && !os.airplane {
                Section("Networks") {
                    ForEach(networks, id: \.self) { name in
                        Button(name) { chosen = name; asking = true }
                    }
                }
            }
        }
        .navigationTitle("Wi-Fi")
        .alert("Join \(chosen)?", isPresented: $asking) {
            Button("Join") { os.notify("Wi-Fi", "Unable to join \(chosen). Signal too trolled.") }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct SwitchPage: View {
    let title: String
    let names: [String]
    @State private var off: Set<String> = []

    var body: some View {
        List(names, id: \.self) { name in
            Toggle(name, isOn: Binding(
                get: { !off.contains(name) },
                set: { on in
                    if on { off.remove(name) } else { off.insert(name) }
                }
            ))
        }
        .navigationTitle(title)
    }
}

struct GeneralPage: View {
    @EnvironmentObject var os: OSState
    @State private var confirmWipe = false

    var body: some View {
        List {
            Section {
                NavigationLink("About") { AboutApp().navigationTitle("About") }
                NavigationLink("Software Update") { UpdatePage() }
                NavigationLink("Storage") { StoragePage() }
            }
            Section {
                Button("Lock Screen") { os.openApp = nil; os.phase = .lock }
                Button("Restart") { os.reboot() }
                Button("Shut Down") { os.shutdown() }
                Button("Erase All Content and Settings", role: .destructive) { confirmWipe = true }
            }
        }
        .navigationTitle("General")
        .alert("Erase TrollOS?", isPresented: $confirmWipe) {
            Button("Erase", role: .destructive) { os.wipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This resets TrollOS inside this app.")
        }
    }
}

struct UpdatePage: View {
    @EnvironmentObject var os: OSState
    @State private var progress = 0.0
    @State private var running = false

    var body: some View {
        List {
            Section {
                Text("TrollOS 3.4").font(.headline)
                Text("Smoother animations and 33% more troll.")
                if running { ProgressView(value: progress) }
                Button(running ? "Downloading..." : "Download and Install") { running = true }
                    .disabled(running)
            }
        }
        .navigationTitle("Software Update")
        .task(id: running) {
            guard running else { return }
            for i in 1...25 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if Task.isCancelled { return }
                progress = Double(i) / 25
            }
            running = false
            os.popup("Update Failed", "The troll ate the update. Try again later.")
        }
    }
}

struct StoragePage: View {
    var body: some View {
        List {
            Section("33.3 GB of 64 GB used") {
                ProgressView(value: 0.52)
                Row(tile: "APP", color: .blue, title: "Apps", value: "12.1 GB")
                Row(tile: "MED", color: .orange, title: "Memes", value: "18.0 GB")
                Row(tile: "OS", color: .gray, title: "TrollOS", value: "3.2 GB")
            }
        }
        .navigationTitle("Storage")
    }
}

struct DisplayPage: View {
    @EnvironmentObject var os: OSState
    @State private var trueTone = true
    var body: some View {
        List {
            Section("Brightness") { Slider(value: $os.brightness, in: 0.2...1) }
            Toggle("True Troll Tone", isOn: $trueTone)
        }
        .navigationTitle("Display")
    }
}

struct WallpaperPage: View {
    @EnvironmentObject var os: OSState
    private let names = ["Ocean", "Jungle", "Sunset", "Night"]
    var body: some View {
        List(0..<4, id: \.self) { i in
            Button {
                os.wallpaper = i
                os.notify("Wallpaper", "\(names[i]) applied.")
            } label: {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: OSState.wallpapers[i], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 70)
                    Text(names[i])
                    Spacer()
                    if os.wallpaper == i { Text("Selected").foregroundColor(.secondary) }
                }
            }
        }
        .navigationTitle("Wallpaper")
    }
}

struct BatteryPage: View {
    @EnvironmentObject var os: OSState
    @State private var low = false
    var body: some View {
        List {
            Toggle("Low Power Mode", isOn: $low)
            Row(tile: "%", color: .green, title: "Level", value: "33%")
            Button("Check Battery Health") {
                os.popup("Battery Health", "Maximum capacity: 333%. Impressive.")
            }
        }
        .navigationTitle("Battery")
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
        case "ver": lines.append("TrollOS 3.33")
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
        ("System", ["kernel.bin", "boot.cfg"])
    ]

    var body: some View {
        List {
            ForEach(folders, id: \.0) { folder in
                Section(folder.0) {
                    ForEach(folder.1, id: \.self) { file in
                        Button {
                            os.popup(file, "Located in \(folder.0).")
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
                    os.popup("Installed", "\(item) is ready to use.")
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
            Text(os.jailbroken ? "Jailbroken" : "Not jailbroken")
            ProgressView(value: os.jailbroken ? 1 : progress).padding(.horizontal, 40)
            Button(running ? "Working..." : "Jailbreak") { running = true }
                .buttonStyle(.borderedProminent)
                .disabled(running || os.jailbroken)
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
            os.popup("Done", "Jailbreak complete.")
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
            Text(page == "troll://home" ? "Welcome to TrollNet."
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
            Section("Legal") {
                Text("TrollOS is a simulation made for fun. It does not change your device.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}
