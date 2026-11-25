import SwiftUI


@main
struct Fiji333App: App {
    @StateObject private var state = AppState()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(state)
        }
    }
}


// Everything here is pretend. The app only changes its own on-screen state.
@MainActor
final class AppState: ObservableObject {
    @Published var jailbroken = false
    @Published var running = false
    @Published var progress = 0.0
    @Published var logs: [String] = ["fiji333 ready (simulation)"]
    @Published var installed: Set<String> = []
    @Published var respringing = false
    @Published var showSuccess = false

    func runExploit(verbose: Bool) async {
        guard !running, !jailbroken else { return }
        running = true
        progress = 0
        logs = ["[*] starting pretend exploit"]
        let steps = ["Checking imaginary device", "Warming up coconuts",
                     "Finding fake kernel slide", "Patching nothing",
                     "Mounting pretend rootfs", "Installing fake loader",
                     "Cleaning up"]
        for (i, step) in steps.enumerated() {
            logs.append("[+] \(step)...")
            if verbose {
                logs.append("    sim value: 0x\(String(Int.random(in: 4096...65535), radix: 16))")
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            progress = Double(i + 1) / Double(steps.count)
        }
        logs.append("[*] done (nothing was modified)")
        running = false
        jailbroken = true
        showSuccess = true
    }

    func respring() async {
        respringing = true
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        respringing = false
    }

    func restore() {
        jailbroken = false
        progress = 0
        installed = []
        logs = ["[*] restored. fiji333 ready (simulation)"]
    }
}


// Settings-style coloured rectangle with short text instead of an icon.
struct Tile: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct Row: View {
    let tile: String
    let color: Color
    let title: String
    var value: String = ""
    var body: some View {
        HStack(spacing: 12) {
            Tile(text: tile, color: color)
            Text(title).foregroundColor(.primary)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}


struct RootView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("verbose") private var verbose = true
    @AppStorage("dark") private var dark = true
    @State private var confirmRun = false
    @State private var confirmRestore = false
    @State private var showWelcome = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(colors: [.teal, .blue], startPoint: .top, endPoint: .bottom))
                            .frame(width: 60, height: 60)
                            .overlay(Text("333").bold().foregroundColor(.white))
                        VStack(alignment: .leading) {
                            Text("fiji333").font(.title2).bold()
                            Text(state.jailbroken ? "Jailbroken (pretend)" : "Not jailbroken")
                                .foregroundColor(state.jailbroken ? .green : .secondary)
                        }
                    }
                }

                Section {
                    Button { confirmRun = true } label: {
                        Row(tile: "JB", color: .red, title: state.running ? "Running..." : "Jailbreak",
                            value: state.jailbroken ? "Done" : "")
                    }
                    .disabled(state.running || state.jailbroken)
                    if state.running {
                        ProgressView(value: state.progress)
                    }
                    NavigationLink { LogView() } label: {
                        Row(tile: ">_", color: .black, title: "Console")
                    }
                }

                Section("Features") {
                    NavigationLink { TweaksView() } label: {
                        Row(tile: "TW", color: .orange, title: "Tweaks")
                    }
                    NavigationLink { StoreView() } label: {
                        Row(tile: "PK", color: .purple, title: "Packages", value: "\(state.installed.count)")
                    }
                    NavigationLink { DeviceView() } label: {
                        Row(tile: "i", color: .gray, title: "Device Info")
                    }
                }

                Section("Settings") {
                    Toggle(isOn: $dark) { Row(tile: "DK", color: .indigo, title: "Dark Mode") }
                    Toggle(isOn: $verbose) { Row(tile: "VB", color: .green, title: "Verbose Log") }
                    NavigationLink { CreditsView() } label: {
                        Row(tile: "CR", color: .pink, title: "Credits")
                    }
                }

                Section {
                    Button { Task { await state.respring() } } label: {
                        Row(tile: "RS", color: .blue, title: "Respring")
                    }
                    Button { confirmRestore = true } label: {
                        Row(tile: "X", color: .red, title: "Restore")
                    }
                } footer: {
                    Text("Simulation only. Nothing on this device is modified.")
                }
                .disabled(state.running)
            }
            .navigationTitle("fiji333")
        }
        .preferredColorScheme(dark ? .dark : .light)
        .alert("Welcome to fiji333", isPresented: $showWelcome) {
            Button("Let's go", role: .cancel) {}
        } message: {
            Text("This is a fake jailbreak for fun. It does not change your device.")
        }
        .confirmationDialog("Start the pretend jailbreak?", isPresented: $confirmRun, titleVisibility: .visible) {
            Button("Start") { Task { await state.runExploit(verbose: verbose) } }
        }
        .alert("Success!", isPresented: $state.showSuccess) {
            Button("Respring") { Task { await state.respring() } }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Pretend jailbreak complete.")
        }
        .alert("Restore?", isPresented: $confirmRestore) {
            Button("Restore", role: .destructive) { state.restore() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This resets the app's fake state.")
        }
        .fullScreenCover(isPresented: $state.respringing) {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("fake respring").font(.footnote).foregroundColor(.gray)
                }
            }
        }
    }
}


struct LogView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        ScrollView {
            Text(state.logs.joined(separator: "\n"))
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color.black)
        .navigationTitle("Console")
    }
}

struct TweaksView: View {
    @AppStorage("t_bar") private var bar = false
    @AppStorage("t_dock") private var dock = false
    @AppStorage("t_anim") private var anim = false
    @AppStorage("t_speed") private var speed = 1.0
    @State private var popup = false

    var body: some View {
        List {
            Section("Pretend tweaks") {
                Toggle(isOn: $bar) { Row(tile: "SB", color: .blue, title: "Rainbow Status Bar") }
                Toggle(isOn: $dock) { Row(tile: "DC", color: .teal, title: "Invisible Dock") }
                Toggle(isOn: $anim) { Row(tile: "AN", color: .orange, title: "Bouncy Animations") }
            }
            Section("Animation speed: \(String(format: "%.1f", speed))x") {
                Slider(value: $speed, in: 0.5...3.0, step: 0.1)
            }
            Button("Apply Tweaks") { popup = true }
        }
        .navigationTitle("Tweaks")
        .alert("Applied (pretend)", isPresented: $popup) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your switches are saved inside the app.")
        }
    }
}

struct Package: Identifiable {
    let name: String
    let info: String
    let color: Color
    var id: String { name }
}

struct StoreView: View {
    @EnvironmentObject var state: AppState
    @State private var selected: Package?
    @State private var locked = false
    @State private var search = ""

    private let packages = [
        Package(name: "CocoTheme", info: "Pretend island theme", color: .brown),
        Package(name: "WaveDock", info: "Pretend wavy dock", color: .blue),
        Package(name: "PalmClock", info: "Pretend clock style", color: .green),
        Package(name: "SunsetCC", info: "Pretend control centre", color: .orange)
    ]

    private var shown: [Package] {
        search.isEmpty ? packages : packages.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List(shown) { pkg in
            Button {
                if state.jailbroken { selected = pkg } else { locked = true }
            } label: {
                Row(tile: String(pkg.name.prefix(2)), color: pkg.color, title: pkg.name,
                    value: state.installed.contains(pkg.name) ? "Installed" : "Get")
            }
        }
        .searchable(text: $search)
        .navigationTitle("Packages")
        .alert("Locked", isPresented: $locked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Run the pretend jailbreak first.")
        }
        .alert(selected?.name ?? "", isPresented: Binding(
            get: { selected != nil },
            set: { if !$0 { selected = nil } }
        ), presenting: selected) { pkg in
            if state.installed.contains(pkg.name) {
                Button("Remove", role: .destructive) { state.installed.remove(pkg.name) }
            } else {
                Button("Install") { state.installed.insert(pkg.name) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { pkg in
            Text(pkg.info)
        }
    }
}

struct DeviceView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        List {
            Row(tile: "OS", color: .gray, title: "iOS", value: UIDevice.current.systemVersion)
            Row(tile: "DV", color: .blue, title: "Model", value: UIDevice.current.model)
            Row(tile: "JB", color: .red, title: "Status", value: state.jailbroken ? "Pretend" : "Stock")
        }
        .navigationTitle("Device Info")
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            Row(tile: "ME", color: .teal, title: "Created by", value: "You")
            Row(tile: "V", color: .gray, title: "Version", value: "1.0")
        }
        .navigationTitle("Credits")
    }
}

