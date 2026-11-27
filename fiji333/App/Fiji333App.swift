import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

// Fiji Studio: design and play your own jailbreak-style prototypes.

@main
struct Fiji333App: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Model

let canvasSize = CGSize(width: 390, height: 844)

let palette: [Color] = [
    .black, Color(white: 0.12), Color(white: 0.25), .gray, .white, .red,
    .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink, .brown, .clear,
    Color(white: 0.75), Color(red: 0.5, green: 0, blue: 0), Color(red: 1, green: 0.5, blue: 0.4),
    Color(red: 1, green: 0.8, blue: 0.3), Color(red: 0.6, green: 1, blue: 0.2),
    Color(red: 0, green: 0.35, blue: 0.15), .mint, .cyan, Color(red: 0, green: 0.1, blue: 0.4),
    Color(red: 0.25, green: 0, blue: 0.4), Color(red: 1, green: 0, blue: 0.8),
    Color(red: 1, green: 0.75, blue: 0.85), Color(red: 0.2, green: 0.12, blue: 0.07),
    Color(red: 0.07, green: 0.09, blue: 0.13), Color.white.opacity(0.2), Color.black.opacity(0.5)
]
let noColor = 15

func swatch(_ index: Int) -> Color {
    palette.indices.contains(index) ? palette[index] : .clear
}

enum Kind: String, Codable, CaseIterable, Identifiable {
    case rect = "Rectangle"
    case circle = "Ellipse"
    case text = "Text"
    case button = "Button"
    case row = "Settings Row"
    case toggle = "Toggle"
    case progress = "Progress Bar"
    case console = "Console"
    case image = "Image"
    case slider = "Slider"
    case tabs = "Tab Bar"
    var id: String { rawValue }
}

enum Trigger: String, Codable, CaseIterable, Identifiable {
    case tap = "On tap"
    case doubleTap = "On double tap"
    case longPress = "On long press"
    case swipeLeft = "On swipe left"
    case swipeRight = "On swipe right"
    case swipeUp = "On swipe up"
    case swipeDown = "On swipe down"
    case delay = "After delay"
    case sliderEnd = "On slider reaches end"
    var id: String { rawValue }
}

enum TapAction: String, Codable, CaseIterable, Identifiable {
    case none = "Nothing"
    case goTo = "Go to screen"
    case back = "Go back"
    case popup = "Show popup"
    case load = "Fill progress bars"
    case respring = "Respring"
    case show = "Show layer"
    case hide = "Hide layer"
    case toggleLayer = "Show / hide layer"
    case animate = "Play layer animation"
    case haptic = "Vibrate"
    case restart = "Restart prototype"
    case recolor = "Change layer colour"
    case setText = "Change layer text"
    var id: String { rawValue }

    var needsScreen: Bool { self == .goTo || self == .load }
    var needsLayer: Bool {
        self == .show || self == .hide || self == .toggleLayer || self == .animate
            || self == .recolor || self == .setText
    }
}

enum ScreenTransition: String, Codable, CaseIterable, Identifiable {
    case instant = "Instant"
    case dissolve = "Dissolve"
    case smart = "Smart animate"
    case slideLeft = "Slide left"
    case slideRight = "Slide right"
    case slideUp = "Slide up"
    case slideDown = "Slide down"
    case zoom = "Zoom"
    var id: String { rawValue }

    var reversed: ScreenTransition {
        switch self {
        case .slideLeft: return .slideRight
        case .slideRight: return .slideLeft
        case .slideUp: return .slideDown
        case .slideDown: return .slideUp
        default: return self
        }
    }

    var effect: AnyTransition {
        switch self {
        case .instant, .smart: return .identity
        case .dissolve: return .opacity
        case .slideLeft: return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .slideRight: return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        case .slideUp: return .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
        case .slideDown: return .asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom))
        case .zoom: return .scale.combined(with: .opacity)
        }
    }
}

enum Easing: String, Codable, CaseIterable, Identifiable {
    case linear = "Linear"
    case easeIn = "Ease in"
    case easeOut = "Ease out"
    case easeInOut = "Ease in and out"
    case spring = "Spring"
    case bouncy = "Bouncy"
    var id: String { rawValue }

    func animation(_ time: Double) -> Animation {
        switch self {
        case .linear: return .linear(duration: time)
        case .easeIn: return .easeIn(duration: time)
        case .easeOut: return .easeOut(duration: time)
        case .easeInOut: return .easeInOut(duration: time)
        case .spring: return .spring(response: time, dampingFraction: 0.75)
        case .bouncy: return .spring(response: time, dampingFraction: 0.45)
        }
    }
}

enum MotionKind: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case fade = "Fade in"
    case fromBottom = "Slide from bottom"
    case fromTop = "Slide from top"
    case fromLeft = "Slide from left"
    case fromRight = "Slide from right"
    case pop = "Pop in"
    case shake = "Shake"
    case spin = "Spin (loop)"
    case pulse = "Pulse (loop)"
    case blink = "Blink (loop)"
    case float = "Float (loop)"
    var id: String { rawValue }

    var loops: Bool { self == .spin || self == .pulse || self == .blink || self == .float }
}

enum PopupPlace: String, Codable, CaseIterable, Identifiable {
    case top = "Top"
    case middle = "Middle"
    case bottom = "Bottom"
    var id: String { rawValue }
}

struct PopupButton: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = "OK"
    var fill = 10
    var ink = 4
    // Holds one follow-up action. Empty means the popup just closes.
    var then: [Interaction] = []
}

struct Interaction: Codable, Identifiable, Equatable {
    var id = UUID()
    var trigger: Trigger = .tap
    var action: TapAction = .goTo
    var wait: Double = 1
    var screen: UUID?
    var layer: UUID?
    var title = "Alert"
    var message = "Something happened."
    var transition: ScreenTransition = .dissolve
    var easing: Easing = .easeInOut
    var duration: Double = 0.35
    var buttons: [PopupButton] = [PopupButton()]
    var popupFill = 1
    var popupInk = 4
    var popupRadius: Double = 24
    var popupDim: Double = 0.45
    var popupPlace: PopupPlace = .middle
    var popupStack = false
    var autoClose: Double = 0
    var color = 8
    var colorText = false
    var newText = "Done"
    // What happens after a respring. Empty means restart the prototype.
    var then: [Interaction] = []

    enum CodingKeys: String, CodingKey {
        case id, trigger, action, wait, screen, layer, title, message, transition, easing, duration
        case buttons, popupFill, popupInk, popupRadius, popupDim, popupPlace, popupStack
        case autoClose, color, colorText, newText, then
    }

    // Points follow-up actions at the new layers when a screen is duplicated.
    mutating func remap(_ ids: [UUID: UUID]) {
        if let old = layer { layer = ids[old] ?? old }
        for i in then.indices { then[i].remap(ids) }
        for i in buttons.indices {
            for j in buttons[i].then.indices { buttons[i].then[j].remap(ids) }
        }
    }
}

// Missing values fall back to defaults so older designs still open.
extension Interaction {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decode(T.self, forKey: key)) ?? fallback
        }
        self.init()
        id = read(.id, id)
        trigger = read(.trigger, trigger)
        action = read(.action, action)
        wait = read(.wait, wait)
        screen = try? c.decode(UUID.self, forKey: .screen)
        layer = try? c.decode(UUID.self, forKey: .layer)
        title = read(.title, title)
        message = read(.message, message)
        transition = read(.transition, transition)
        easing = read(.easing, easing)
        duration = read(.duration, duration)
        buttons = read(.buttons, buttons)
        popupFill = read(.popupFill, popupFill)
        popupInk = read(.popupInk, popupInk)
        popupRadius = read(.popupRadius, popupRadius)
        popupDim = read(.popupDim, popupDim)
        popupPlace = read(.popupPlace, popupPlace)
        popupStack = read(.popupStack, popupStack)
        autoClose = read(.autoClose, autoClose)
        color = read(.color, color)
        colorText = read(.colorText, colorText)
        newText = read(.newText, newText)
        then = read(.then, then)
    }
}

struct Element: Codable, Identifiable, Equatable {
    var id = UUID()
    var link = UUID()
    var kind: Kind
    var name = ""
    var x: Double = 195
    var y: Double = 422
    var w: Double = 200
    var h: Double = 60
    var text = ""
    var fill = 10
    var fill2: Int?
    var ink = 4
    var stroke = 4
    var strokeWidth: Double = 0
    var radius: Double = 12
    var fontSize: Double = 17
    var weight = 2
    var align = 1
    var opacity: Double = 1
    var rotation: Double = 0
    var shadow: Double = 0
    var locked = false
    var hidden = false
    var image: Data?
    var imageFit = false
    var motion: MotionKind = .none
    var motionEasing: Easing = .easeOut
    var motionTime: Double = 0.6
    var motionDelay: Double = 0
    var interactions: [Interaction] = []
    var consoleSpeed: Double = 0.45
    var consoleWait: Double = 0
    var consoleLoop = false
    var consoleScroll = true
    var value: Double = 0.5
    var showValue = true
    var tabTargets: [UUID?] = []

    var label: String { name.isEmpty ? kind.rawValue : name }

    enum CodingKeys: String, CodingKey {
        case id, link, kind, name, x, y, w, h, text, fill, fill2, ink, stroke, strokeWidth
        case radius, fontSize, weight, align, opacity, rotation, shadow, locked, hidden
        case image, imageFit, motion, motionEasing, motionTime, motionDelay, interactions
        case consoleSpeed, consoleWait, consoleLoop, consoleScroll
        case value, showValue, tabTargets
    }
}

// Reads designs saved by this version and by the first version.
extension Element {
    private enum OldKeys: String, CodingKey {
        case action, target, popupTitle, popupText
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decode(T.self, forKey: key)) ?? fallback
        }
        self.init(kind: try c.decode(Kind.self, forKey: .kind))
        id = read(.id, id)
        link = read(.link, id)
        name = read(.name, name)
        x = read(.x, x)
        y = read(.y, y)
        w = read(.w, w)
        h = read(.h, h)
        text = read(.text, text)
        fill = read(.fill, fill)
        fill2 = try? c.decode(Int.self, forKey: .fill2)
        ink = read(.ink, ink)
        stroke = read(.stroke, stroke)
        strokeWidth = read(.strokeWidth, strokeWidth)
        radius = read(.radius, radius)
        fontSize = read(.fontSize, fontSize)
        weight = read(.weight, weight)
        align = read(.align, align)
        opacity = read(.opacity, opacity)
        rotation = read(.rotation, rotation)
        shadow = read(.shadow, shadow)
        locked = read(.locked, locked)
        hidden = read(.hidden, hidden)
        image = try? c.decode(Data.self, forKey: .image)
        imageFit = read(.imageFit, imageFit)
        motion = read(.motion, motion)
        motionEasing = read(.motionEasing, motionEasing)
        motionTime = read(.motionTime, motionTime)
        motionDelay = read(.motionDelay, motionDelay)
        interactions = read(.interactions, interactions)
        consoleSpeed = read(.consoleSpeed, consoleSpeed)
        consoleWait = read(.consoleWait, consoleWait)
        consoleLoop = read(.consoleLoop, consoleLoop)
        consoleScroll = read(.consoleScroll, consoleScroll)
        value = read(.value, value)
        showValue = read(.showValue, showValue)
        tabTargets = read(.tabTargets, tabTargets)

        if !c.contains(.interactions) {
            let old = try decoder.container(keyedBy: OldKeys.self)
            if let action = try? old.decode(TapAction.self, forKey: .action), action != .none {
                var item = Interaction()
                item.action = action
                item.screen = try? old.decode(UUID.self, forKey: .target)
                item.title = (try? old.decode(String.self, forKey: .popupTitle)) ?? item.title
                item.message = (try? old.decode(String.self, forKey: .popupText)) ?? item.message
                interactions = [item]
            }
        }
    }
}

struct Frame: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var fill = 0
    var elements: [Element] = []
}

struct Project: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var frames: [Frame]
}

func makeElement(_ kind: Kind) -> Element {
    var e = Element(kind: kind)
    switch kind {
    case .rect: e.w = 200; e.h = 120; e.fill = 2
    case .circle: e.w = 100; e.h = 100; e.fill = 12
    case .text: e.text = "Text"; e.fontSize = 28; e.fill = 15
    case .button: e.text = "Jailbreak"; e.radius = 16
    case .row: e.text = "Tweaks"; e.w = 350; e.h = 52; e.fill = 1
    case .toggle: e.text = "Enable tweaks"; e.w = 350; e.h = 52; e.fill = 1
    case .progress: e.w = 300; e.h = 10; e.fill = 8
    case .image: e.w = 250; e.h = 250; e.fill = 2
    case .slider: e.w = 300; e.h = 60; e.fill = 10; e.fontSize = 15
    case .tabs:
        e.text = "Home\nTweaks\nSettings"
        e.w = 370; e.h = 56; e.y = 780; e.fill = 1; e.radius = 18; e.fontSize = 15
    case .console:
        e.text = "[*] starting\n[+] loading modules\n[+] applying tweaks\n[*] done"
        e.w = 350; e.h = 260; e.fill = 1; e.ink = 8; e.fontSize = 13
    }
    return e
}

// MARK: - Templates

enum Templates {
    static func blank() -> Project {
        Project(name: "Untitled", frames: [Frame(name: "Screen 1")])
    }

    static func jailbreak() -> Project {
        var home = Frame(name: "Home")
        var done = Frame(name: "Done")

        var title = makeElement(.text)
        title.text = "fiji333"; title.y = 150; title.w = 340; title.fontSize = 48
        var logo = makeElement(.rect)
        logo.y = 290; logo.w = 130; logo.h = 130; logo.fill = 9; logo.radius = 30
        var bar = makeElement(.progress)
        bar.y = 520
        var go = makeElement(.button)
        go.y = 640; go.w = 280
        go.interactions = [Interaction(action: .load, screen: done.id)]
        logo.motion = .float
        logo.motionTime = 1.2
        title.motion = .fromTop
        home.elements = [title, logo, bar, go]

        var ok = makeElement(.text)
        ok.text = "Jailbroken"; ok.y = 120; ok.w = 340; ok.ink = 8; ok.fontSize = 40
        var log = makeElement(.console)
        log.y = 330
        var row = makeElement(.row)
        row.y = 530
        row.interactions = [Interaction(action: .popup, title: "Tweaks",
                                        message: "No tweaks installed yet.")]
        var spring = makeElement(.button)
        spring.text = "Respring"; spring.y = 640; spring.w = 280; spring.interactions = [Interaction(action: .respring)]
        var back = makeElement(.button)
        back.text = "Back"; back.y = 720; back.w = 280; back.fill = 2; back.interactions = [Interaction(action: .back)]
        done.elements = [ok, log, row, spring, back]

        return Project(name: "Jailbreak Starter", frames: [home, done])
    }

    static func terminal() -> Project {
        var screen = Frame(name: "Shell")
        var log = makeElement(.console)
        log.y = 360; log.h = 520
        var run = makeElement(.button)
        run.text = "Run"; run.y = 700; run.fill = 8; run.ink = 0
        run.interactions = [Interaction(action: .popup, title: "Shell",
                                        message: "Command finished.")]
        screen.elements = [log, run]
        return Project(name: "Hacker Console", frames: [screen])
    }
}

// MARK: - Store

@MainActor
final class Store: ObservableObject {
    @Published var projects: [Project] = [] {
        didSet { save() }
    }
    @Published var editing: UUID?
    @Published var playing: UUID?
    @Published var playStart: UUID?
    @Published var clipboard: Element?
    private let oldKey = "fijistudio.projects"
    private var pending: Task<Void, Never>?

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fijistudio.json")
    }

    init() {
        let saved = (try? Data(contentsOf: fileURL))
            ?? UserDefaults.standard.data(forKey: oldKey)
        if let data = saved,
           let list = try? JSONDecoder().decode([Project].self, from: data) {
            projects = list
        } else {
            if let data = saved {
                try? data.write(to: fileURL.appendingPathExtension("backup"))
            }
            projects = [Templates.jailbreak()]
        }
    }

    private func save() {
        pending?.cancel()
        pending = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            flush()
        }
    }

    func flush() {
        if let data = try? JSONEncoder().encode(projects) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func add(_ project: Project) {
        projects.insert(project, at: 0)
    }

    func update(_ project: Project) {
        if let i = projects.firstIndex(where: { $0.id == project.id }) {
            projects[i] = project
        }
    }

    func play(_ project: UUID, from frame: UUID? = nil) {
        playStart = frame
        playing = project
    }
}

struct DataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .png] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

func readFile(_ url: URL) -> Data? {
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    return try? Data(contentsOf: url)
}

// Shrinks pictures so designs stay small.
func prepareImage(_ data: Data) -> (data: Data, size: CGSize)? {
    guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
        return nil
    }
    let ratio = min(1, 1200 / max(image.size.width, image.size.height))
    let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let small = UIGraphicsImageRenderer(size: size, format: format).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
    }
    let alpha = image.cgImage?.alphaInfo
    let opaque = alpha == CGImageAlphaInfo.none || alpha == .noneSkipFirst || alpha == .noneSkipLast
    let output = opaque ? small.jpegData(compressionQuality: 0.85) : small.pngData()
    guard let result = output else { return nil }
    return (result, size)
}

let imageCache = NSCache<NSData, UIImage>()

func cachedImage(_ data: Data) -> UIImage? {
    if let hit = imageCache.object(forKey: data as NSData) { return hit }
    guard let image = UIImage(data: data) else { return nil }
    imageCache.setObject(image, forKey: data as NSData)
    return image
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("accent") private var accent = 10
    var body: some View {
        ZStack {
            if let id = store.editing, let project = store.projects.first(where: { $0.id == id }) {
                EditorView(project: project)
                    .id(id)
            } else {
                HomeView()
            }
            if let id = store.playing, let project = store.projects.first(where: { $0.id == id }) {
                PlayerView(project: project, start: store.playStart)
                    .zIndex(1)
            }
        }
        .tint(swatch(accent))
        .onChange(of: scenePhase) { phase in
            if phase != .active { store.flush() }
        }
        .statusBarHidden(store.playing != nil)
        .persistentSystemOverlays(store.playing != nil ? .hidden : .automatic)
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var store: Store
    @State private var renaming: Project?
    @State private var newName = ""
    @State private var deleting: Project?
    @State private var message = ""
    @State private var showMessage = false
    @State private var showAbout = false
    @State private var showSettings = false
    @AppStorage("studioName") private var studioName = "Fiji Studio"
    @State private var importing = false
    @State private var exporting = false
    @State private var document = DataDocument(data: Data())
    @State private var filename = "design"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Settings and slider limits") { showSettings = true }
                }
                Section("New file") {
                    Button("Blank design") { create(Templates.blank()) }
                    Button("Template: Jailbreak Starter") { create(Templates.jailbreak()) }
                    Button("Template: Hacker Console") { create(Templates.terminal()) }
                    Button("Open from Files") { importing = true }
                    Button("Import from clipboard") { importProject() }
                }
                Section("Your files") {
                    if store.projects.isEmpty {
                        Text("No files yet").foregroundColor(.secondary)
                    }
                    ForEach(store.projects) { project in
                        projectRow(project)
                    }
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result {
                    load(readFile(url))
                }
            }
            .navigationTitle(studioName)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") { showSettings = true }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("About") { showAbout = true }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert("Rename file", isPresented: Binding(
                get: { renaming != nil },
                set: { if !$0 { renaming = nil } }
            )) {
                TextField("Name", text: $newName)
                Button("Save") { rename() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete file?", isPresented: Binding(
                get: { deleting != nil },
                set: { if !$0 { deleting = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    store.projects.removeAll { $0.id == deleting?.id }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert(message, isPresented: $showMessage) {
                Button("OK", role: .cancel) {}
            }
            .alert("Fiji Studio", isPresented: $showAbout) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("A design game. Prototypes are simulations and do not change your device.")
            }
        }
        .fileExporter(isPresented: $exporting, document: document,
                      contentType: .json, defaultFilename: filename) { result in
            if case .success = result { show("Saved to Files") }
        }
    }

    private func projectRow(_ project: Project) -> some View {
        HStack {
            Button {
                store.editing = project.id
            } label: {
                HStack(spacing: 12) {
                    if let first = project.frames.first {
                        Thumbnail(frame: first)
                    }
                    VStack(alignment: .leading) {
                        Text(project.name).foregroundColor(.primary)
                        Text("\(project.frames.count) screens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            Menu("More") {
                Button("Play") { store.play(project.id) }
                Button("Rename") { newName = project.name; renaming = project }
                Button("Duplicate") {
                    var copy = project
                    copy.id = UUID()
                    copy.name += " copy"
                    store.add(copy)
                }
                Button("Save to Files") { saveFile(project) }
                Button("Copy to clipboard") { export(project) }
                Button("Delete", role: .destructive) { deleting = project }
            }
        }
    }

    private func create(_ project: Project) {
        store.add(project)
        store.editing = project.id
    }

    private func rename() {
        guard var project = renaming, !newName.isEmpty else { return }
        project.name = newName
        store.update(project)
    }

    private func export(_ project: Project) {
        if let data = try? JSONEncoder().encode(project),
           let string = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = string
            show("Copied to clipboard")
        }
    }

    private func importProject() {
        load(UIPasteboard.general.string?.data(using: .utf8))
    }

    private func load(_ data: Data?) {
        if let data = data,
           var project = try? JSONDecoder().decode(Project.self, from: data),
           !project.frames.isEmpty {
            project.id = UUID()
            store.add(project)
            show("Imported \(project.name)")
        } else {
            show("That is not a Fiji Studio design")
        }
    }

    private func saveFile(_ project: Project) {
        if let data = try? JSONEncoder().encode(project) {
            document = DataDocument(data: data)
            filename = project.name
            exporting = true
        }
    }

    private func show(_ text: String) {
        message = text
        showMessage = true
    }
}

struct ScreenPicture: View {
    let frame: Frame
    var body: some View {
        ZStack {
            swatch(frame.fill)
            ForEach(frame.elements.filter { !$0.hidden }) { element in
                ElementView(element: element)
                    .position(x: element.x, y: element.y)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
    }
}

struct SettingsView: View {
    @AppStorage("unlimited") private var unlimited = false
    @AppStorage("snapStep") private var snapStep = 5.0
    @AppStorage("gridSize") private var gridSize = 30.0
    @AppStorage("nudgeStep") private var nudgeStep = 1.0
    @AppStorage("gap") private var gap = 16.0
    @AppStorage("exitHold") private var exitHold = 2.0
    @AppStorage("showHint") private var showHint = true
    @AppStorage("vibration") private var vibration = true
    @AppStorage("respringTime") private var respringTime = 2.2
    @AppStorage("respringLock") private var respringLock = true
    @AppStorage("accent") private var accent = 10
    @AppStorage("editorBack") private var editorBack = 30
    @AppStorage("outline") private var outline = 23
    @AppStorage("studioName") private var studioName = "Fiji Studio"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Customise") {
                    TextField("Main menu title", text: $studioName)
                    Swatches(title: "Accent colour", selection: $accent)
                    Swatches(title: "Editor background", selection: $editorBack)
                    Swatches(title: "Selection outline", selection: $outline)
                }
                Section {
                    Toggle("Unlock slider limits", isOn: $unlimited)
                } header: {
                    Text("Limits")
                } footer: {
                    Text("Allows huge sizes, off-screen positions, long timings and deeper zoom.")
                }
                Section("Editor") {
                    SliderRow(title: "Snap step", value: $snapStep, range: 1...50,
                              unlocked: 1...500)
                    SliderRow(title: "Grid size", value: $gridSize, range: 10...100,
                              unlocked: 5...500)
                    SliderRow(title: "Arrow move step", value: $nudgeStep, range: 1...50,
                              unlocked: 0.1...500)
                    SliderRow(title: "Default spacing", value: $gap, range: 0...80,
                              unlocked: -500...1000)
                }
                Section("Prototype") {
                    SliderRow(title: "Hold to exit (s)", value: $exitHold, range: 1...5, step: 0.5,
                              unlocked: 0.8...15)
                    Toggle("Show exit hint", isOn: $showHint)
                    Toggle("Allow vibration", isOn: $vibration)
                }
                Section("Respring") {
                    SliderRow(title: "Loading time (s)", value: $respringTime, range: 0.5...6,
                              step: 0.5, unlocked: 0.3...60)
                    Toggle("Lock screen afterwards", isOn: $respringLock)
                }
                Button("Reset settings", role: .destructive) { reset() }
            }
            .navigationTitle("Settings")
            .tint(swatch(accent))
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func reset() {
        unlimited = false
        snapStep = 5
        gridSize = 30
        nudgeStep = 1
        gap = 16
        exitHold = 2
        showHint = true
        vibration = true
        respringTime = 2.2
        respringLock = true
        accent = 10
        editorBack = 30
        outline = 23
        studioName = "Fiji Studio"
    }
}

// MARK: - Arrange and spacing

struct ArrangeView: View {
    @ObservedObject var model: EditorModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gap") private var gap = 16.0
    @State private var picked: Set<UUID> = []
    @State private var columns = 2
    @State private var copies = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("1. Choose layers") {
                    HStack {
                        Button("Select all") {
                            picked = Set(model.frame.elements.filter { !$0.locked }.map { $0.id })
                        }
                        Spacer()
                        Button("Clear") { picked = [] }
                    }
                    .buttonStyle(.bordered)
                    ForEach(model.frame.elements.filter { !$0.locked }) { element in
                        Button {
                            if picked.contains(element.id) { picked.remove(element.id) }
                            else { picked.insert(element.id) }
                        } label: {
                            HStack {
                                Text(element.label + " " + String(element.text.prefix(14)))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Text(picked.contains(element.id) ? "Selected" : "")
                            }
                        }
                    }
                }
                Section("2. Spacing") {
                    SliderRow(title: "Gap", value: $gap, range: 0...80, unlocked: -500...1000)
                    Button("Stack vertically") { stack(vertical: true) }
                    Button("Stack horizontally") { stack(vertical: false) }
                    Stepper("Columns: \(columns)", value: $columns, in: 1...12)
                    Button("Arrange as grid") { makeGrid() }
                    Button("Space evenly down") { distribute(vertical: true) }
                    Button("Space evenly across") { distribute(vertical: false) }
                }
                .disabled(picked.count < 2)
                Section("Align") {
                    Button("Centre on screen across") { apply { $0.x = 195 } }
                    Button("Centre on screen down") { centreDown() }
                    Button("Align left edges") { alignLeft() }
                    Button("Align top edges") { alignTop() }
                    Button("Same width as first") { sameSize(width: true) }
                    Button("Same height as first") { sameSize(width: false) }
                }
                .disabled(picked.isEmpty)
                Section("Repeat") {
                    Stepper("Copies: \(copies)", value: $copies, in: 1...30)
                    Button("Repeat downwards") { repeatDown() }
                }
                .disabled(picked.count != 1)
            }
            .navigationTitle("Arrange")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
        .onAppear {
            if let id = model.selected { picked = [id] }
        }
    }

    private var chosen: [Element] {
        model.frame.elements.filter { picked.contains($0.id) && !$0.locked }
    }

    private func apply(_ edit: (inout Element) -> Void) {
        model.checkpoint()
        for item in chosen {
            model.change(item.id, edit)
        }
    }

    private func place(_ items: [Element]) {
        model.checkpoint()
        for item in items {
            model.change(item.id) { $0.x = item.x; $0.y = item.y }
        }
    }

    private func stack(vertical: Bool) {
        var items = chosen.sorted { vertical ? $0.y < $1.y : $0.x < $1.x }
        guard let first = items.first else { return }
        var edge = vertical ? first.y - first.h / 2 : first.x - first.w / 2
        for i in items.indices {
            if vertical {
                items[i].y = edge + items[i].h / 2
                edge += items[i].h + gap
            } else {
                items[i].x = edge + items[i].w / 2
                edge += items[i].w + gap
            }
        }
        place(items)
    }

    private func makeGrid() {
        var items = chosen.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        guard !items.isEmpty else { return }
        let cellW = items.map { $0.w }.max() ?? 0
        let cellH = items.map { $0.h }.max() ?? 0
        let total = Double(columns) * cellW + Double(columns - 1) * gap
        let left = 195 - total / 2
        let top = items.map { $0.y - $0.h / 2 }.min() ?? 0
        for i in items.indices {
            let column = Double(i % columns)
            let row = Double(i / columns)
            items[i].x = left + column * (cellW + gap) + cellW / 2
            items[i].y = top + row * (cellH + gap) + cellH / 2
        }
        place(items)
    }

    private func distribute(vertical: Bool) {
        var items = chosen.sorted { vertical ? $0.y < $1.y : $0.x < $1.x }
        guard items.count > 2, let first = items.first, let last = items.last else { return }
        let start = vertical ? first.y : first.x
        let end = vertical ? last.y : last.x
        let space = (end - start) / Double(items.count - 1)
        for i in items.indices {
            if vertical { items[i].y = start + Double(i) * space }
            else { items[i].x = start + Double(i) * space }
        }
        place(items)
    }

    private func centreDown() {
        var items = chosen
        let top = items.map { $0.y - $0.h / 2 }.min() ?? 0
        let bottom = items.map { $0.y + $0.h / 2 }.max() ?? 0
        let move = 422 - (top + bottom) / 2
        for i in items.indices { items[i].y += move }
        place(items)
    }

    private func alignLeft() {
        let edge = chosen.map { $0.x - $0.w / 2 }.min() ?? 0
        apply { $0.x = edge + $0.w / 2 }
    }

    private func alignTop() {
        let edge = chosen.map { $0.y - $0.h / 2 }.min() ?? 0
        apply { $0.y = edge + $0.h / 2 }
    }

    private func sameSize(width: Bool) {
        guard let first = chosen.first else { return }
        apply {
            if width { $0.w = first.w } else { $0.h = first.h }
        }
    }

    private func repeatDown() {
        guard let source = chosen.first else { return }
        model.checkpoint()
        for i in 1...copies {
            var copy = source
            copy.id = UUID()
            copy.link = UUID()
            copy.y += Double(i) * (source.h + gap)
            model.frame.elements.append(copy)
        }
    }
}

struct Thumbnail: View {
    let frame: Frame
    var body: some View {
        ScreenPicture(frame: frame)
            .scaleEffect(0.12)
            .frame(width: canvasSize.width * 0.12, height: canvasSize.height * 0.12)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray))
            .allowsHitTesting(false)
    }
}

// MARK: - Element rendering

struct ElementView: View {
    let element: Element
    var progress: Double = 0.35
    var isOn = false
    var lines: Int?
    var value: Double?
    var selectedTab = 0

    var body: some View {
        content
            .frame(width: element.w, height: element.h)
            .overlay(border)
            .shadow(color: Color.black.opacity(element.shadow > 0 ? 0.55 : 0),
                    radius: element.shadow, x: 0, y: element.shadow / 2)
            .opacity(element.opacity)
            .rotationEffect(.degrees(element.rotation))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: element.radius, style: .continuous)
    }

    private var paint: LinearGradient {
        let first = swatch(element.fill)
        let second = element.fill2.map { swatch($0) } ?? first
        return LinearGradient(colors: [first, second], startPoint: .top, endPoint: .bottom)
    }

    private var font: Font {
        let weights: [Font.Weight] = [.light, .regular, .semibold, .black]
        let index = min(max(element.weight, 0), 3)
        return .system(size: element.fontSize, weight: weights[index], design: .rounded)
    }

    private var textAlignment: TextAlignment {
        if element.align == 0 { return .leading }
        return element.align == 2 ? .trailing : .center
    }

    private var boxAlignment: Alignment {
        if element.align == 0 { return .leading }
        return element.align == 2 ? .trailing : .center
    }

    @ViewBuilder private var border: some View {
        if element.strokeWidth > 0 {
            if element.kind == .circle {
                Ellipse().stroke(swatch(element.stroke), lineWidth: element.strokeWidth)
            } else {
                shape.stroke(swatch(element.stroke), lineWidth: element.strokeWidth)
            }
        }
    }

    @ViewBuilder private var picture: some View {
        if let data = element.image, let image = cachedImage(data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: element.imageFit ? .fit : .fill)
                .frame(width: element.w, height: element.h)
                .clipShape(shape)
        } else {
            shape.fill(paint).overlay(Text("No image").foregroundColor(.white))
        }
    }

    private var sliderLook: some View {
        let amount = min(1, max(0, value ?? element.value))
        return VStack(spacing: 6) {
            if element.showValue {
                Text("\(Int((amount * 100).rounded()))%")
                    .font(font)
                    .foregroundColor(swatch(element.ink))
            }
            GeometryReader { geo in
                let travel = max(0, geo.size.width - 28)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(white: 0.3)).frame(height: 8)
                    Capsule().fill(paint).frame(width: travel * amount + 14, height: 8)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 3)
                        .offset(x: travel * amount)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private var tabsLook: some View {
        let names = element.text.components(separatedBy: "\n")
        return HStack(spacing: 4) {
            ForEach(names.indices, id: \.self) { i in
                Text(names[i])
                    .font(font)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(swatch(element.ink))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: element.radius * 0.75, style: .continuous)
                            .fill(Color.white.opacity(i == selectedTab ? 0.25 : 0))
                    )
            }
        }
        .padding(4)
        .background(shape.fill(paint))
    }

    @ViewBuilder private var content: some View {
        switch element.kind {
        case .rect:
            shape.fill(paint)
        case .circle:
            Ellipse().fill(paint)
        case .image:
            picture
        case .slider:
            sliderLook
        case .tabs:
            tabsLook
        case .text, .button:
            Text(element.text)
                .font(font)
                .multilineTextAlignment(textAlignment)
                .foregroundColor(swatch(element.ink))
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: boxAlignment)
                .background(shape.fill(paint))
        case .row:
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.orange)
                    .frame(width: 30, height: 30)
                    .overlay(Text(String(element.text.prefix(2))).font(.caption.bold()))
                Text(element.text).font(font).foregroundColor(swatch(element.ink))
                Spacer()
                Text(">").foregroundColor(.gray)
            }
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
            .background(shape.fill(paint))
        case .toggle:
            HStack {
                Text(element.text).font(font).foregroundColor(swatch(element.ink))
                Spacer()
                Capsule()
                    .fill(isOn ? Color.green : Color(white: 0.35))
                    .frame(width: 51, height: 31)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle().fill(Color.white).padding(2)
                    }
            }
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
            .background(shape.fill(paint))
        case .progress:
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(white: 0.3))
                    Capsule()
                        .fill(paint)
                        .frame(width: geo.size.width * progress)
                }
            }
        case .console:
            Text(visibleText)
                .font(.system(size: element.fontSize, design: .monospaced))
                .foregroundColor(swatch(element.ink))
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(shape.fill(paint))
                .clipped()
        }
    }

    private var visibleText: String {
        guard let count = lines else { return element.text }
        let all = element.text.components(separatedBy: "\n")
        var shown = Array(all.prefix(count))
        if element.consoleScroll {
            let fits = max(1, Int((element.h - 24) / (max(1, element.fontSize) * 1.22)))
            shown = Array(shown.suffix(fits))
        }
        return shown.joined(separator: "\n")
    }
}

// MARK: - Live console

struct LiveConsole: View {
    let element: Element
    let run: String
    @State private var count = 0

    var body: some View {
        ElementView(element: element, lines: count)
            .task(id: run) { await type() }
    }

    private func type() async {
        count = 0
        let total = element.text.components(separatedBy: "\n").count
        if element.consoleWait > 0 {
            try? await Task.sleep(nanoseconds: UInt64(element.consoleWait * 1_000_000_000))
        }
        let pause = UInt64(max(0.01, element.consoleSpeed) * 1_000_000_000)
        while !Task.isCancelled {
            if count >= total {
                if !element.consoleLoop { return }
                try? await Task.sleep(nanoseconds: max(pause, 800_000_000))
                if Task.isCancelled { return }
                count = 0
            }
            try? await Task.sleep(nanoseconds: pause)
            if Task.isCancelled { return }
            count += 1
        }
    }
}

// MARK: - Animation

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 14 * sin(amount * .pi * 8), y: 0))
    }
}

struct Motion: ViewModifier {
    let element: Element
    let replay: Int
    @State private var on = false

    private var kind: MotionKind { element.motion }
    private var waiting: Bool { !on }

    private var alpha: Double {
        switch kind {
        case .fade, .fromBottom, .fromTop, .fromLeft, .fromRight, .pop: return waiting ? 0 : 1
        case .blink: return on ? 0.15 : 1
        default: return 1
        }
    }

    private var shift: CGSize {
        switch kind {
        case .fromBottom: return CGSize(width: 0, height: waiting ? 500 : 0)
        case .fromTop: return CGSize(width: 0, height: waiting ? -500 : 0)
        case .fromLeft: return CGSize(width: waiting ? -420 : 0, height: 0)
        case .fromRight: return CGSize(width: waiting ? 420 : 0, height: 0)
        case .float: return CGSize(width: 0, height: on ? -16 : 0)
        default: return .zero
        }
    }

    private var size: CGFloat {
        if kind == .pop { return waiting ? 0.2 : 1 }
        if kind == .pulse { return on ? 1.1 : 1 }
        return 1
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(size)
            .rotationEffect(.degrees(kind == .spin && on ? 360 : 0))
            .modifier(ShakeEffect(amount: kind == .shake && on ? 1 : 0))
            .opacity(alpha)
            .offset(shift)
            .onAppear { start() }
            .onChange(of: replay) { _ in
                var reset = Transaction()
                reset.disablesAnimations = true
                withTransaction(reset) { on = false }
                DispatchQueue.main.async { start() }
            }
    }

    private func start() {
        guard kind != .none else { return }
        var animation = element.motionEasing.animation(max(0.1, element.motionTime))
        if kind.loops {
            animation = animation.repeatForever(autoreverses: kind != .spin)
        }
        withAnimation(animation.delay(element.motionDelay)) { on = true }
    }
}

// MARK: - Editor

@MainActor
final class EditorModel: ObservableObject {
    @Published var project: Project
    @Published var frameIndex = 0
    @Published var selected: UUID?
    @Published var past: [Project] = []
    @Published var future: [Project] = []

    init(project: Project) {
        self.project = project
    }

    var frame: Frame {
        get { project.frames[min(frameIndex, project.frames.count - 1)] }
        set { project.frames[min(frameIndex, project.frames.count - 1)] = newValue }
    }

    var element: Element? {
        frame.elements.first { $0.id == selected }
    }

    func checkpoint() {
        if past.last == project { return }
        past.append(project)
        if past.count > 50 { past.removeFirst() }
        future = []
    }

    func undo() {
        while past.last == project { past.removeLast() }
        guard let previous = past.popLast() else { return }
        future.append(project)
        restore(previous)
    }

    func redo() {
        guard let next = future.popLast() else { return }
        past.append(project)
        restore(next)
    }

    private func restore(_ value: Project) {
        project = value
        frameIndex = min(frameIndex, value.frames.count - 1)
        selected = nil
    }

    func add(_ kind: Kind) {
        checkpoint()
        let new = makeElement(kind)
        frame.elements.append(new)
        selected = new.id
    }

    func change(_ id: UUID, _ edit: (inout Element) -> Void) {
        if let i = frame.elements.firstIndex(where: { $0.id == id }) {
            edit(&frame.elements[i])
        }
    }

    func duplicate() {
        guard var copy = element else { return }
        checkpoint()
        copy.id = UUID()
        copy.link = UUID()
        copy.x += 16
        copy.y += 16
        frame.elements.append(copy)
        selected = copy.id
    }

    func paste(_ source: Element) {
        checkpoint()
        var copy = source
        copy.id = UUID()
        if frame.elements.contains(where: { $0.link == copy.link }) {
            copy.link = UUID()
            copy.x += 16
            copy.y += 16
        }
        frame.elements.append(copy)
        selected = copy.id
    }

    func addImage(_ data: Data) {
        guard let result = prepareImage(data) else { return }
        checkpoint()
        var new = makeElement(.image)
        new.image = result.data
        new.w = 280
        new.h = min(700, 280 * Double(result.size.height / result.size.width))
        frame.elements.append(new)
        selected = new.id
    }

    func delete() {
        guard let id = selected else { return }
        checkpoint()
        frame.elements.removeAll { $0.id == id }
        selected = nil
    }

    func reorder(toFront: Bool) {
        guard let item = element else { return }
        checkpoint()
        frame.elements.removeAll { $0.id == item.id }
        if toFront { frame.elements.append(item) }
        else { frame.elements.insert(item, at: 0) }
    }

    func addFrame(copying: Bool) {
        checkpoint()
        var new = copying ? frame : Frame(name: "")
        new.id = UUID()
        new.name = "Screen \(project.frames.count + 1)"
        if copying {
            var ids: [UUID: UUID] = [:]
            for i in new.elements.indices {
                let fresh = UUID()
                ids[new.elements[i].id] = fresh
                new.elements[i].id = fresh
            }
            for i in new.elements.indices {
                for j in new.elements[i].interactions.indices {
                    new.elements[i].interactions[j].remap(ids)
                }
            }
        }
        project.frames.append(new)
        frameIndex = project.frames.count - 1
        selected = nil
    }

    func deleteFrame() {
        guard project.frames.count > 1 else { return }
        checkpoint()
        project.frames.remove(at: frameIndex)
        frameIndex = max(0, frameIndex - 1)
        selected = nil
    }
}

enum Panel: String, Identifiable {
    case design, layers, screen, arrange
    var id: String { rawValue }
}

struct EditorView: View {
    @EnvironmentObject var store: Store
    @StateObject private var model: EditorModel
    @State private var panel: Panel?
    @State private var snap = true
    @State private var grid = false
    @State private var arrows = false
    @AppStorage("accent") private var accent = 10
    @AppStorage("editorBack") private var editorBack = 30
    @AppStorage("nudgeStep") private var nudgeStep = 1.0
    @State private var pickingPhoto = false
    @State private var photo: PhotosPickerItem?
    @State private var importingImage = false
    @State private var exporting = false
    @State private var document = DataDocument(data: Data())
    @State private var exportType = UTType.json

    init(project: Project) {
        _model = StateObject(wrappedValue: EditorModel(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            frameTabs
            CanvasView(model: model, snap: snap, grid: grid)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(swatch(editorBack))
                .fileImporter(isPresented: $importingImage, allowedContentTypes: [.image]) { result in
                    if case .success(let url) = result, let data = readFile(url) {
                        model.addImage(data)
                    }
                }
            if model.selected != nil {
                selectionBar
                if arrows { nudgeBar }
            }
            bottomBar
        }
        .background(Color(white: 0.13).ignoresSafeArea())
        .sheet(item: $panel) { item in
            Group {
                switch item {
                case .design: InspectorView(model: model)
                case .layers: LayersView(model: model)
                case .screen: ScreenView(model: model)
                case .arrange: ArrangeView(model: model)
                }
            }
            .presentationDetents([.medium, .large])
            .tint(swatch(accent))
        }
        .onChange(of: model.project) { value in
            store.update(value)
        }
        .photosPicker(isPresented: $pickingPhoto, selection: $photo, matching: .images)
        .onChange(of: photo) { item in
            guard let item = item else { return }
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self) {
                    model.addImage(data)
                }
                photo = nil
            }
        }
    }

    private func exportDesign() {
        if let data = try? JSONEncoder().encode(model.project) {
            document = DataDocument(data: data)
            exportType = .json
            exporting = true
        }
    }

    private func exportScreen() {
        let renderer = ImageRenderer(content: ScreenPicture(frame: model.frame))
        renderer.scale = 3
        if let data = renderer.uiImage?.pngData() {
            document = DataDocument(data: data)
            exportType = .png
            exporting = true
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button("Files") { store.flush(); store.editing = nil }
            Spacer()
            Text(model.project.name).bold().lineLimit(1)
            Spacer()
            Button("Undo") { model.undo() }.disabled(model.past.isEmpty)
            Button("Redo") { model.redo() }.disabled(model.future.isEmpty)
            Menu("Export") {
                Button("Save design to Files") { exportDesign() }
                Button("Save screen as PNG") { exportScreen() }
            }
            Button("Play") {
                store.update(model.project)
                store.play(model.project.id, from: model.frame.id)
            }
            .buttonStyle(.borderedProminent)
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .fileExporter(isPresented: $exporting, document: document, contentType: exportType,
                      defaultFilename: model.project.name) { _ in }
    }

    private var frameTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(model.project.frames.enumerated()), id: \.element.id) { index, frame in
                    Button(frame.name) {
                        model.frameIndex = index
                        model.selected = nil
                    }
                    .buttonStyle(.bordered)
                    .tint(index == model.frameIndex ? .blue : .gray)
                }
                Button("+ Screen") { model.addFrame(copying: false) }
            }
            .font(.caption)
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }

    private var nudgeBar: some View {
        HStack {
            Button("Left") { nudge(-1, 0) }
            Button("Up") { nudge(0, -1) }
            Button("Down") { nudge(0, 1) }
            Button("Right") { nudge(1, 0) }
        }
        .buttonStyle(.bordered)
        .font(.caption)
        .padding(.bottom, 6)
    }

    private func nudge(_ dx: Double, _ dy: Double) {
        guard let item = model.element, !item.locked else { return }
        model.checkpoint()
        model.change(item.id) {
            $0.x += dx * nudgeStep
            $0.y += dy * nudgeStep
        }
    }

    private var selectionBar: some View {
        HStack {
            Button("Edit") { model.checkpoint(); panel = .design }
            Spacer()
            Button("Duplicate") { model.duplicate() }
            Spacer()
            Button("Copy") { store.clipboard = model.element }
            Spacer()
            Button("Front") { model.reorder(toFront: true) }
            Spacer()
            Button("Back") { model.reorder(toFront: false) }
            Spacer()
            Button("Delete", role: .destructive) { model.delete() }
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var bottomBar: some View {
        HStack {
            Menu("+ Insert") {
                ForEach(Kind.allCases.filter { $0 != .image }) { kind in
                    Button(kind.rawValue) { model.add(kind) }
                }
                Button("Image from Photos") { pickingPhoto = true }
                Button("Image from Files") { importingImage = true }
                if let copied = store.clipboard {
                    Button("Paste") { model.paste(copied) }
                }
            }
            Spacer()
            Button("Layers") { panel = .layers }
            Spacer()
            Button("Arrange") { panel = .arrange }
            Spacer()
            Button("Screen") { model.checkpoint(); panel = .screen }
            Spacer()
            Menu("View") {
                Toggle("Snap", isOn: $snap)
                Toggle("Grid", isOn: $grid)
                Toggle("Arrow buttons", isOn: $arrows)
            }
        }
        .padding()
        .background(Color(white: 0.17))
    }
}

struct CanvasView: View {
    @ObservedObject var model: EditorModel
    let snap: Bool
    let grid: Bool
    @AppStorage("outline") private var outline = 23
    @State private var origin: CGPoint?
    @AppStorage("unlimited") private var unlimited = false
    @AppStorage("snapStep") private var snapStep = 5.0
    @AppStorage("gridSize") private var gridSize = 30.0
    @State private var zoom: CGFloat = 1
    @State private var pan = CGSize.zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var moving = CGSize.zero

    var body: some View {
        GeometryReader { geo in
            let fit = max(0.1, min((geo.size.width - 24) / canvasSize.width,
                                   (geo.size.height - 16) / canvasSize.height))
            board
                .scaleEffect(fit * zoom * pinch)
                .position(x: geo.size.width / 2 + pan.width + moving.width,
                          y: geo.size.height / 2 + pan.height + moving.height)
        }
        .contentShape(Rectangle())
        .gesture(panning)
        .simultaneousGesture(zooming)
        .clipped()
        .overlay(alignment: .bottomTrailing) { zoomButtons }
    }

    private var zoomRange: ClosedRange<CGFloat> {
        unlimited ? 0.05...30 : 0.4...5
    }

    private func limited(_ value: CGFloat) -> CGFloat {
        min(zoomRange.upperBound, max(zoomRange.lowerBound, value))
    }

    private var board: some View {
        ZStack {
            swatch(model.frame.fill)
                .onTapGesture { model.selected = nil }
            ForEach(model.frame.elements) { element in
                item(element)
            }
            if grid { gridLines }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .coordinateSpace(name: "canvas")
        .clipped()
        .border(Color.gray.opacity(0.5))
    }

    private var gridLines: some View {
        Path { path in
            let space = CGFloat(max(5, gridSize))
            for x in stride(from: space, to: canvasSize.width, by: space) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
            }
            for y in stride(from: space, to: canvasSize.height, by: space) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
            }
        }
        .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
        .allowsHitTesting(false)
    }

    private var zoomButtons: some View {
        HStack {
            Button("-") { zoom = limited(zoom / 1.25) }
            Button("Fit") { zoom = 1; pan = .zero }
            Button("+") { zoom = limited(zoom * 1.25) }
        }
        .buttonStyle(.bordered)
        .font(.caption)
        .padding(6)
    }

    private var panning: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .updating($moving) { value, state, _ in state = value.translation }
            .onEnded { value in
                pan.width += value.translation.width
                pan.height += value.translation.height
            }
    }

    private var zooming: some Gesture {
        MagnificationGesture()
            .updating($pinch) { value, state, _ in state = value }
            .onEnded { value in zoom = limited(zoom * value) }
    }

    private func item(_ element: Element) -> some View {
        ElementView(element: element)
            .opacity(element.hidden ? 0.25 : 1)
            .contentShape(Rectangle())
            .overlay {
                if model.selected == element.id {
                    Rectangle().stroke(swatch(outline), lineWidth: 3)
                }
            }
            .onTapGesture { model.selected = element.id }
            .gesture(drag(element), including: element.locked ? .subviews : .all)
            .allowsHitTesting(!element.locked)
            .position(x: element.x, y: element.y)
    }

    private func drag(_ element: Element) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("canvas"))
            .onChanged { value in
                if origin == nil {
                    model.checkpoint()
                    model.selected = element.id
                    origin = CGPoint(x: element.x, y: element.y)
                }
                guard let start = origin else { return }
                var x = Double(start.x + value.translation.width)
                var y = Double(start.y + value.translation.height)
                if snap {
                    let unit = max(1, snapStep)
                    x = (x / unit).rounded() * unit
                    y = (y / unit).rounded() * unit
                    if abs(x - 195) < 10 { x = 195 }
                    if abs(y - 422) < 10 { y = 422 }
                }
                model.change(element.id) { $0.x = x; $0.y = y }
            }
            .onEnded { _ in origin = nil }
    }
}

// MARK: - Panels

struct Swatches: View {
    let title: String
    @Binding var selection: Int
    private let columns = Array(repeating: GridItem(.flexible()), count: 8)

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            LazyVGrid(columns: columns) {
                ForEach(palette.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(palette[i])
                        .frame(height: 30)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(selection == i ? Color.cyan : Color.gray,
                                    lineWidth: selection == i ? 3 : 1))
                        .overlay(Text(i == noColor ? "none" : "").font(.system(size: 9)))
                        .contentShape(Rectangle())
                        .onTapGesture { selection = i }
                }
            }
        }
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var unlocked: ClosedRange<Double>?
    @AppStorage("unlimited") private var unlimited = false

    private var limits: ClosedRange<Double> {
        unlimited ? (unlocked ?? range) : range
    }

    // Always includes the current value so turning limits back on changes nothing.
    private var sliderRange: ClosedRange<Double> {
        min(limits.lowerBound, value)...max(limits.upperBound, value)
    }

    private var typed: Binding<Double> {
        Binding(
            get: { value },
            set: { value = min(max($0, limits.lowerBound), limits.upperBound) }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                TextField(title, value: typed, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
            }
            HStack {
                Button("-") { typed.wrappedValue = value - step }
                    .buttonStyle(.bordered)
                Slider(value: $value, in: sliderRange)
                Button("+") { typed.wrappedValue = value + step }
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct InspectorView: View {
    @ObservedObject var model: EditorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let element = model.element {
                    form(binding(element))
                } else {
                    Text("Nothing selected")
                }
            }
            .navigationTitle(model.element?.kind.rawValue ?? "Design")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func binding(_ fallback: Element) -> Binding<Element> {
        Binding(
            get: { model.frame.elements.first { $0.id == fallback.id } ?? fallback },
            set: { value in model.change(fallback.id) { $0 = value } }
        )
    }

    private func form(_ e: Binding<Element>) -> some View {
        Form {
            Section {
                NavigationLink("Animation: \(e.wrappedValue.motion.rawValue)") {
                    MotionPage(element: e)
                }
                NavigationLink("Interactions: \(e.wrappedValue.interactions.count)") {
                    InteractionsPage(model: model, element: e)
                }
            }
            if e.wrappedValue.kind == .image {
                ImageSection(element: e)
            }
            if e.wrappedValue.kind == .slider {
                Section("Slider") {
                    SliderRow(title: "Start value", value: e.value, range: 0...1, step: 0.05)
                    Toggle("Show percentage", isOn: e.showValue)
                    Text("Add the trigger On slider reaches end for slide to jailbreak.")
                        .font(.caption)
                }
            }
            if e.wrappedValue.kind == .tabs {
                TabsSection(model: model, element: e)
            }
            if e.wrappedValue.kind == .console {
                consoleSection(e)
            }
            if hasText(e.wrappedValue.kind) {
                textSection(e)
            }
            layoutSection(e)
            styleSection(e)
            Section("Layer") {
                TextField("Layer name", text: e.name)
                Toggle("Locked", isOn: e.locked)
                Toggle("Hidden at start", isOn: e.hidden)
            }
        }
    }

    private func consoleSection(_ e: Binding<Element>) -> some View {
        Section("Console speed") {
            HStack {
                Button("Slow") { e.wrappedValue.consoleSpeed = 1.2 }
                Button("Normal") { e.wrappedValue.consoleSpeed = 0.45 }
                Button("Fast") { e.wrappedValue.consoleSpeed = 0.15 }
                Button("Turbo") { e.wrappedValue.consoleSpeed = 0.04 }
            }
            .buttonStyle(.bordered)
            .font(.caption)
            SliderRow(title: "Seconds per line", value: e.consoleSpeed, range: 0.02...3,
                      step: 0.05, unlocked: 0.01...60)
            SliderRow(title: "Start delay (s)", value: e.consoleWait, range: 0...10,
                      step: 0.5, unlocked: 0...600)
            Toggle("Loop", isOn: e.consoleLoop)
            Toggle("Auto scroll", isOn: e.consoleScroll)
        }
    }

    private func hasText(_ kind: Kind) -> Bool {
        kind == .text || kind == .button || kind == .row || kind == .toggle || kind == .console
            || kind == .slider || kind == .tabs
    }

    private func textSection(_ e: Binding<Element>) -> some View {
        Section("Text") {
            TextField("Text", text: e.text, axis: .vertical)
            SliderRow(title: "Font size", value: e.fontSize, range: 8...96,
                      unlocked: 1...500)
            Picker("Weight", selection: e.weight) {
                Text("Light").tag(0)
                Text("Regular").tag(1)
                Text("Bold").tag(2)
                Text("Black").tag(3)
            }
            Picker("Align", selection: e.align) {
                Text("Left").tag(0)
                Text("Centre").tag(1)
                Text("Right").tag(2)
            }
            .pickerStyle(.segmented)
            Swatches(title: "Text colour", selection: e.ink)
        }
    }

    private func layoutSection(_ e: Binding<Element>) -> some View {
        Section("Layout") {
            SliderRow(title: "X", value: e.x, range: 0...390,
                      unlocked: -3000...3000)
            SliderRow(title: "Y", value: e.y, range: 0...844,
                      unlocked: -3000...4000)
            SliderRow(title: "Width", value: e.w, range: 4...390,
                      unlocked: 1...5000)
            SliderRow(title: "Height", value: e.h, range: 4...844,
                      unlocked: 1...5000)
            SliderRow(title: "Rotation", value: e.rotation, range: -180...180,
                      unlocked: -3600...3600)
            HStack {
                Button("Left") { e.wrappedValue.x = e.wrappedValue.w / 2 }
                Button("Centre") { e.wrappedValue.x = 195 }
                Button("Right") { e.wrappedValue.x = 390 - e.wrappedValue.w / 2 }
            }
            .buttonStyle(.bordered)
            HStack {
                Button("Top") { e.wrappedValue.y = e.wrappedValue.h / 2 }
                Button("Middle") { e.wrappedValue.y = 422 }
                Button("Bottom") { e.wrappedValue.y = 844 - e.wrappedValue.h / 2 }
            }
            .buttonStyle(.bordered)
            Button("Fill screen") {
                var value = e.wrappedValue
                value.x = 195; value.y = 422; value.w = 390; value.h = 844; value.radius = 0
                e.wrappedValue = value
            }
        }
    }

    private func styleSection(_ e: Binding<Element>) -> some View {
        Section("Style") {
            Swatches(title: "Fill", selection: e.fill)
            Toggle("Gradient", isOn: Binding(
                get: { e.wrappedValue.fill2 != nil },
                set: { e.wrappedValue.fill2 = $0 ? 12 : nil }
            ))
            if e.wrappedValue.fill2 != nil {
                Swatches(title: "Gradient end", selection: Binding(
                    get: { e.wrappedValue.fill2 ?? 12 },
                    set: { e.wrappedValue.fill2 = $0 }
                ))
            }
            SliderRow(title: "Corner radius", value: e.radius, range: 0...200,
                      unlocked: 0...2000)
            SliderRow(title: "Opacity", value: e.opacity, range: 0.05...1, step: 0.05)
            SliderRow(title: "Shadow", value: e.shadow, range: 0...40,
                      unlocked: 0...300)
            SliderRow(title: "Border width", value: e.strokeWidth, range: 0...20,
                      unlocked: 0...200)
            if e.wrappedValue.strokeWidth > 0 {
                Swatches(title: "Border colour", selection: e.stroke)
            }
        }
    }
}

struct ImageSection: View {
    @Binding var element: Element
    @State private var photo: PhotosPickerItem?

    var body: some View {
        Section("Image") {
            PhotosPicker("Replace image", selection: $photo, matching: .images)
            Toggle("Fit whole picture", isOn: $element.imageFit)
        }
        .onChange(of: photo) { item in
            guard let item = item else { return }
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self),
                   let result = prepareImage(data) {
                    element.image = result.data
                }
                photo = nil
            }
        }
    }
}

struct MotionPage: View {
    @Binding var element: Element
    @State private var replay = 0

    var body: some View {
        Form {
            Section("Preview") {
                ZStack {
                    Text(element.label)
                        .bold()
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .modifier(Motion(element: element, replay: replay))
                        .id(element.motion)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .clipped()
                Button("Play preview") { replay += 1 }
            }
            Picker("Animation", selection: $element.motion) {
                ForEach(MotionKind.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Easing", selection: $element.motionEasing) {
                ForEach(Easing.allCases) { Text($0.rawValue).tag($0) }
            }
            SliderRow(title: "Duration (s)", value: $element.motionTime, range: 0.1...4, step: 0.1,
                      unlocked: 0.05...120)
            SliderRow(title: "Delay (s)", value: $element.motionDelay, range: 0...10, step: 0.1,
                      unlocked: 0...600)
        }
        .navigationTitle("Animation")
    }
}

struct InteractionsPage: View {
    @ObservedObject var model: EditorModel
    @Binding var element: Element

    var body: some View {
        Form {
            ForEach($element.interactions) { $item in
                Section {
                    InteractionEditor(model: model, item: $item)
                    Button("Remove interaction", role: .destructive) {
                        let id = item.id
                        element.interactions.removeAll { $0.id == id }
                    }
                }
            }
            Button("+ Add interaction") {
                element.interactions.append(Interaction())
            }
        }
        .navigationTitle("Interactions")
    }
}

struct TabsSection: View {
    @ObservedObject var model: EditorModel
    @Binding var element: Element

    private var names: [String] {
        element.text.components(separatedBy: "\n")
    }

    var body: some View {
        Section("Tabs (one name per line in Text)") {
            ForEach(names.indices, id: \.self) { i in
                Picker(names[i] + " opens", selection: target(i)) {
                    Text("Nothing").tag(UUID?.none)
                    ForEach(model.project.frames) { frame in
                        Text(frame.name).tag(Optional(frame.id))
                    }
                }
            }
            Button("+ Add tab") { element.text += "\nTab" }
            Button("Remove last tab", role: .destructive) {
                element.text = names.dropLast().joined(separator: "\n")
            }
            .disabled(names.count < 2)
        }
    }

    private func target(_ index: Int) -> Binding<UUID?> {
        Binding(
            get: { element.tabTargets.indices.contains(index) ? element.tabTargets[index] : nil },
            set: { value in
                var list = element.tabTargets
                while list.count <= index { list.append(nil) }
                list[index] = value
                element.tabTargets = list
            }
        )
    }
}

// A binding to the single follow-up action stored in a list.
func followUp(_ list: Binding<[Interaction]>, fallback: TapAction) -> Binding<Interaction> {
    Binding(
        get: { list.wrappedValue.first ?? Interaction(action: fallback) },
        set: { list.wrappedValue = [$0] }
    )
}

struct FollowPage: View {
    @ObservedObject var model: EditorModel
    @Binding var item: Interaction
    let title: String

    var body: some View {
        Form {
            InteractionEditor(model: model, item: $item, showTrigger: false)
        }
        .navigationTitle(title)
    }
}

struct PopupPage: View {
    @ObservedObject var model: EditorModel
    @Binding var item: Interaction

    var body: some View {
        Form {
            Section("Message") {
                TextField("Popup title", text: $item.title)
                TextField("Popup message", text: $item.message, axis: .vertical)
            }
            ForEach($item.buttons) { $button in
                Section("Button") {
                    TextField("Button text", text: $button.title)
                    NavigationLink("When pressed: \(button.then.first?.action.rawValue ?? "Nothing")") {
                        FollowPage(model: model,
                                   item: followUp($button.then, fallback: .none),
                                   title: button.title)
                    }
                    Swatches(title: "Button colour", selection: $button.fill)
                    Swatches(title: "Button text colour", selection: $button.ink)
                    Button("Remove button", role: .destructive) {
                        let id = button.id
                        item.buttons.removeAll { $0.id == id }
                    }
                }
            }
            Section("Buttons: \(item.buttons.count)") {
                Button("+ Add button") {
                    var new = PopupButton()
                    new.title = "Button \(item.buttons.count + 1)"
                    item.buttons.append(new)
                }
                Button("Use OK and Cancel") {
                    var cancel = PopupButton()
                    cancel.title = "Cancel"
                    cancel.fill = 2
                    item.buttons = [cancel, PopupButton()]
                }
                Toggle("Stack buttons vertically", isOn: $item.popupStack)
                if item.buttons.isEmpty {
                    Text("With no buttons, tapping outside closes the popup.")
                        .font(.caption)
                }
            }
            Section("Look") {
                Picker("Position", selection: $item.popupPlace) {
                    ForEach(PopupPlace.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Swatches(title: "Background", selection: $item.popupFill)
                Swatches(title: "Text colour", selection: $item.popupInk)
                SliderRow(title: "Corner radius", value: $item.popupRadius, range: 0...50,
                          unlocked: 0...200)
                SliderRow(title: "Darken behind", value: $item.popupDim, range: 0...1, step: 0.05)
                SliderRow(title: "Close by itself after (s, 0 is off)", value: $item.autoClose,
                          range: 0...20, unlocked: 0...600)
            }
        }
        .navigationTitle("Popup")
    }
}

struct InteractionEditor: View {
    @ObservedObject var model: EditorModel
    @Binding var item: Interaction
    var showTrigger = true

    var body: some View {
        Group {
            if showTrigger {
                Picker("Trigger", selection: $item.trigger) {
                    ForEach(Trigger.allCases) { Text($0.rawValue).tag($0) }
                }
                if item.trigger == .delay {
                    SliderRow(title: "Wait (s)", value: $item.wait, range: 0.1...30, step: 0.1,
                              unlocked: 0.1...3600)
                }
            }
            Picker("Action", selection: $item.action) {
                ForEach(TapAction.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        if item.action.needsScreen {
            Picker("Destination", selection: $item.screen) {
                Text("None").tag(UUID?.none)
                ForEach(model.project.frames) { frame in
                    Text(frame.name).tag(Optional(frame.id))
                }
            }
            Picker("Transition", selection: $item.transition) {
                ForEach(ScreenTransition.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Easing", selection: $item.easing) {
                ForEach(Easing.allCases) { Text($0.rawValue).tag($0) }
            }
            SliderRow(title: "Duration (s)", value: $item.duration, range: 0.1...2, step: 0.05,
                      unlocked: 0.05...60)
        }
        if item.action == .load {
            Text("The bars fill first, then the destination opens.")
                .font(.caption)
        }
        if item.action.needsLayer {
            Picker("Layer", selection: $item.layer) {
                Text("None").tag(UUID?.none)
                ForEach(model.frame.elements) { layer in
                    Text(layer.label + " " + String(layer.text.prefix(12))).tag(Optional(layer.id))
                }
            }
        }
        if item.action == .recolor {
            Toggle("Change text colour instead", isOn: $item.colorText)
            Swatches(title: "New colour", selection: $item.color)
        }
        if item.action == .setText {
            TextField("New text", text: $item.newText, axis: .vertical)
        }
        if item.action == .popup {
            NavigationLink("Edit popup (\(item.buttons.count) buttons)") {
                PopupPage(model: model, item: $item)
            }
        }
        if item.action == .respring {
            NavigationLink("After respring: \(item.then.first?.action.rawValue ?? "Restart prototype")") {
                FollowPage(model: model,
                           item: followUp($item.then, fallback: .restart),
                           title: "After respring")
            }
            Text("Choose Nothing to stay on the same screen.")
                .font(.caption)
        }
    }
}

struct LayersView: View {
    @ObservedObject var model: EditorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(model.frame.elements.reversed())) { element in
                    Button {
                        model.selected = element.id
                        dismiss()
                    } label: {
                        HStack {
                            Text(element.label)
                            if element.locked { Text("Locked").font(.caption2) }
                            if element.hidden { Text("Hidden").font(.caption2) }
                            Spacer()
                            Text(element.text.components(separatedBy: "\n").first ?? "")
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: remove)
            }
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EditButton() }
        }
    }

    private func move(from: IndexSet, to: Int) {
        model.checkpoint()
        var list = Array(model.frame.elements.reversed())
        list.move(fromOffsets: from, toOffset: to)
        model.frame.elements = list.reversed()
    }

    private func remove(at offsets: IndexSet) {
        model.checkpoint()
        var list = Array(model.frame.elements.reversed())
        list.remove(atOffsets: offsets)
        model.frame.elements = list.reversed()
        model.selected = nil
    }
}

struct ScreenView: View {
    @ObservedObject var model: EditorModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Screen name", text: Binding(
                    get: { model.frame.name },
                    set: { model.frame.name = $0 }
                ))
                Swatches(title: "Background", selection: Binding(
                    get: { model.frame.fill },
                    set: { model.frame.fill = $0 }
                ))
                Button("Duplicate screen") { model.addFrame(copying: true); dismiss() }
                Button("Delete screen", role: .destructive) { model.deleteFrame(); dismiss() }
                    .disabled(model.project.frames.count < 2)
            }
            .navigationTitle("Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

// MARK: - Prototype player

struct Step {
    let screen: UUID
    let transition: ScreenTransition
    let easing: Easing
    let duration: Double
}

enum RespringStage {
    case idle, shrink, black, lock
}

struct RespringOverlay: View {
    let stage: RespringStage
    let unlock: () -> Void

    var body: some View {
        ZStack {
            if stage == .shrink {
                Color.black.opacity(0.45)
            }
            if stage == .black {
                Color.black
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.25)
            }
            if stage == .lock {
                lockScreen
                    .transition(.opacity.combined(with: .scale(scale: 1.08)))
            }
        }
    }

    private var lockScreen: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.3), .indigo, .teal],
                           startPoint: .top, endPoint: .bottom)
            VStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 2) {
                        Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                            .font(.headline)
                        Text(context.date, format: .dateTime.hour().minute())
                            .font(.system(size: 96, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundStyle(.ultraThickMaterial)
                            .environment(\.colorScheme, .light)
                    }
                }
                .padding(.top, 80)
                Spacer()
                Text("Swipe up to open")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.35)))
                Capsule()
                    .frame(width: 140, height: 5)
                    .padding(.top, 18)
                    .padding(.bottom, 10)
            }
            .foregroundColor(.white)
        }
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 30).onEnded { drag in
            if drag.translation.height < -60 { unlock() }
        })
    }
}

struct PopupOverlay: View {
    let item: Interaction
    let choose: (PopupButton?) -> Void

    private var place: Alignment {
        switch item.popupPlace {
        case .top: return .top
        case .middle: return .center
        case .bottom: return .bottom
        }
    }

    var body: some View {
        ZStack(alignment: place) {
            Color.black
                .opacity(item.popupDim)
                .contentShape(Rectangle())
                .onTapGesture {
                    if item.buttons.isEmpty { choose(nil) }
                }
            card
                .padding(.horizontal, 30)
                .padding(.vertical, 60)
        }
        .task {
            guard item.autoClose > 0 else { return }
            try? await Task.sleep(nanoseconds: UInt64(item.autoClose * 1_000_000_000))
            if !Task.isCancelled { choose(nil) }
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            Text(item.title).font(.headline)
            if !item.message.isEmpty {
                Text(item.message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            if item.popupStack || item.buttons.count > 2 {
                if item.buttons.count > 6 {
                    ScrollView { VStack(spacing: 8) { buttonList } }
                        .frame(maxHeight: 320)
                } else {
                    VStack(spacing: 8) { buttonList }
                }
            } else if !item.buttons.isEmpty {
                HStack(spacing: 8) { buttonList }
            }
        }
        .foregroundColor(swatch(item.popupInk))
        .padding(18)
        .frame(maxWidth: 320)
        .background(swatch(item.popupFill))
        .clipShape(RoundedRectangle(cornerRadius: item.popupRadius, style: .continuous))
        .shadow(radius: 20)
    }

    private var buttonList: some View {
        ForEach(item.buttons) { button in
            Button {
                choose(button)
            } label: {
                Text(button.title)
                    .bold()
                    .foregroundColor(swatch(button.ink))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(swatch(button.fill))
                    .clipShape(RoundedRectangle(cornerRadius: item.popupRadius / 2,
                                                style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

struct PlayerView: View {
    @EnvironmentObject var store: Store
    let project: Project
    let start: UUID?

    @State private var current: UUID?
    @State private var layer = UUID()
    @State private var transition = ScreenTransition.instant
    @State private var history: [Step] = []
    @State private var progress = 0.0
    @State private var loading: Task<Void, Never>?
    @State private var timers: [Task<Void, Never>] = []
    @State private var switches: Set<UUID> = []
    @State private var visibility: [UUID: Bool] = [:]
    @State private var replays: [UUID: Int] = [:]
    @State private var visit = 0
    @State private var popup: Interaction?
    @State private var popupVisit = 0
    @State private var afterRespring: Interaction?
    @State private var sliders: [UUID: Double] = [:]
    @State private var tabChoice: [UUID: Int] = [:]
    @State private var colors: [UUID: Int] = [:]
    @State private var inks: [UUID: Int] = [:]
    @State private var texts: [UUID: String] = [:]
    @State private var stage = RespringStage.idle
    @State private var respringTask: Task<Void, Never>?
    @AppStorage("respringTime") private var respringTime = 2.2
    @AppStorage("respringLock") private var respringLock = true
    @State private var menu = false
    @State private var hint = true
    @AppStorage("exitHold") private var exitHold = 2.0
    @AppStorage("showHint") private var showHint = true
    @AppStorage("vibration") private var vibration = true

    private var frame: Frame {
        let id = current ?? start
        return project.frames.first { $0.id == id } ?? project.frames[0]
    }

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / canvasSize.width, geo.size.height / canvasSize.height)
            ZStack {
                swatch(frame.fill == noColor ? 0 : frame.fill)
                ZStack {
                    screenLayer(frame)
                        .id(layer)
                        .transition(transition.effect)
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
                .scaleEffect(scale)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .blur(radius: receding ? 24 : 0)
                .scaleEffect(receding ? 0.88 : 1)
                if hint && showHint { hintView }
                if let item = popup {
                    PopupOverlay(item: item, choose: choose)
                        .id(popupVisit)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
                RespringOverlay(stage: stage, unlock: unlock)
                    .allowsHitTesting(stage != .idle)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(LongPressGesture(minimumDuration: max(0.8, exitHold)).onEnded { _ in menu = true })
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear { schedule() }
        .task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            hint = false
        }
        .onDisappear {
            cancelAll()
            respringTask?.cancel()
        }
        .confirmationDialog("Prototype", isPresented: $menu) {
            Button("Restart") {
                respringTask?.cancel()
                stage = .idle
                restart()
            }
            Button("Exit prototype", role: .destructive) { store.playing = nil }
        }
    }

    private var hintView: some View {
        VStack {
            Spacer()
            Text("Hold for \(String(format: "%g", exitHold)) seconds to exit")
                .font(.footnote)
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 30)
        }
        .allowsHitTesting(false)
    }

    private func screenLayer(_ screen: Frame) -> some View {
        ZStack {
            swatch(screen.fill == noColor ? 0 : screen.fill)
            ForEach(screen.elements, id: \.link) { element in
                playable(element)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private func isVisible(_ element: Element) -> Bool {
        visibility[element.id] ?? !element.hidden
    }

    private func has(_ element: Element, _ triggers: [Trigger]) -> GestureMask {
        element.interactions.contains { triggers.contains($0.trigger) } ? .all : .subviews
    }

    private func playable(_ element: Element) -> some View {
        let swipes: [Trigger] = [.swipeLeft, .swipeRight, .swipeUp, .swipeDown]
        return content(element)
            .contentShape(Rectangle())
            .gesture(TapGesture(count: 2).onEnded { fire(element, .doubleTap) },
                     including: has(element, [.doubleTap]))
            .onTapGesture { tap(element) }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in fire(element, .longPress) },
                including: has(element, [.longPress]))
            .simultaneousGesture(
                DragGesture(minimumDistance: 25).onEnded { swipe(element, $0.translation) },
                including: has(element, swipes))
            .modifier(Motion(element: element, replay: replays[element.id] ?? 0))
            .opacity(isVisible(element) ? 1 : 0)
            .allowsHitTesting(isVisible(element))
            .position(x: element.x, y: element.y)
    }

    // The layer as it looks now, after any colour or text changes.
    private func live(_ element: Element) -> Element {
        var copy = element
        if let color = colors[element.id] {
            copy.fill = color
            copy.fill2 = nil
        }
        if let ink = inks[element.id] { copy.ink = ink }
        if let text = texts[element.id] { copy.text = text }
        return copy
    }

    @ViewBuilder private func content(_ element: Element) -> some View {
        let shown = live(element)
        if element.kind == .console {
            LiveConsole(element: shown,
                        run: "\(visit)-\(replays[element.id] ?? 0)-\(element.id)-\(shown.text)")
        } else if element.kind == .slider {
            ElementView(element: shown, value: sliders[element.id])
                .overlay(sliderTouch(element))
        } else if element.kind == .tabs {
            ElementView(element: shown, selectedTab: selectedTab(element))
                .overlay(tabTouch(shown))
        } else {
            ElementView(element: shown, progress: progress,
                        isOn: switches.contains(element.id))
        }
    }

    private func sliderTouch(_ element: Element) -> some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let travel = max(1, geo.size.width - 28)
                            let amount = (drag.location.x - 14) / travel
                            sliders[element.id] = Double(min(1, max(0, amount)))
                        }
                        .onEnded { _ in
                            if (sliders[element.id] ?? 0) >= 0.98 { fire(element, .sliderEnd) }
                        }
                )
        }
    }

    private func selectedTab(_ element: Element) -> Int {
        if let match = element.tabTargets.firstIndex(where: { $0 == frame.id }) { return match }
        return tabChoice[element.id] ?? 0
    }

    private func tabTouch(_ element: Element) -> some View {
        let count = element.text.components(separatedBy: "\n").count
        return HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { i in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { openTab(element, i) }
            }
        }
        .id(count)
    }

    private func openTab(_ element: Element, _ index: Int) {
        withAnimation { tabChoice[element.id] = index }
        fire(element, .tap)
        if element.tabTargets.indices.contains(index), let target = element.tabTargets[index] {
            go(Interaction(action: .goTo, screen: target))
        }
    }

    private func choose(_ button: PopupButton?) {
        withAnimation(.easeOut(duration: 0.2)) { popup = nil }
        if let next = button?.then.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if store.playing != nil { run(next) }
            }
        }
    }

    private func tap(_ element: Element) {
        if element.kind == .toggle {
            withAnimation {
                if switches.contains(element.id) { switches.remove(element.id) }
                else { switches.insert(element.id) }
            }
        }
        fire(element, .tap)
    }

    private func swipe(_ element: Element, _ move: CGSize) {
        if abs(move.width) > abs(move.height) {
            fire(element, move.width < 0 ? .swipeLeft : .swipeRight)
        } else {
            fire(element, move.height < 0 ? .swipeUp : .swipeDown)
        }
    }

    private func fire(_ element: Element, _ trigger: Trigger) {
        for item in element.interactions where item.trigger == trigger {
            run(item)
        }
    }

    // Starts the "After delay" timers for the current screen.
    private func schedule() {
        timers.forEach { $0.cancel() }
        timers = []
        for element in frame.elements {
            for item in element.interactions where item.trigger == .delay {
                let task = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(max(0.1, item.wait) * 1_000_000_000))
                    if Task.isCancelled { return }
                    run(item)
                }
                timers.append(task)
            }
        }
    }

    private func run(_ item: Interaction) {
        switch item.action {
        case .none:
            break
        case .goTo:
            go(item)
        case .back:
            goBack()
        case .popup:
            popupVisit += 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { popup = item }
        case .load:
            load(item)
        case .respring:
            respring(then: item.then.first)
        case .show:
            setLayer(item.layer, visible: true)
        case .hide:
            setLayer(item.layer, visible: false)
        case .toggleLayer:
            if let target = frame.elements.first(where: { $0.id == item.layer }) {
                setLayer(target.id, visible: !isVisible(target))
            }
        case .animate:
            if let id = item.layer { replays[id, default: 0] += 1 }
        case .haptic:
            if vibration {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        case .restart:
            restart()
        case .recolor:
            if let id = item.layer {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if item.colorText { inks[id] = item.color }
                    else { colors[id] = item.color }
                }
            }
        case .setText:
            if let id = item.layer { texts[id] = item.newText }
        }
    }

    private func setLayer(_ id: UUID?, visible: Bool) {
        guard let id = id else { return }
        withAnimation(.easeInOut(duration: 0.25)) { visibility[id] = visible }
        if visible { replays[id, default: 0] += 1 }
    }

    private func go(_ item: Interaction) {
        guard let id = item.screen, id != frame.id,
              project.frames.contains(where: { $0.id == id }) else { return }
        history.append(Step(screen: frame.id, transition: item.transition,
                            easing: item.easing, duration: item.duration))
        move(to: id, item.transition, item.easing, item.duration)
    }

    private func goBack() {
        guard let step = history.popLast() else { return }
        move(to: step.screen, step.transition.reversed, step.easing, step.duration)
    }

    private func move(to id: UUID, _ style: ScreenTransition, _ easing: Easing, _ time: Double) {
        loading?.cancel()
        timers.forEach { $0.cancel() }
        transition = style
        // Wait one cycle so the old screen picks up the new transition.
        DispatchQueue.main.async {
            if style == .instant {
                layer = UUID()
                current = id
                progress = 0
            } else {
                withAnimation(easing.animation(time)) {
                    if style != .smart { layer = UUID() }
                    current = id
                    progress = 0
                }
            }
            visit += 1
            schedule()
        }
    }

    private func load(_ item: Interaction) {
        loading?.cancel()
        loading = Task { @MainActor in
            for i in 0...40 {
                withAnimation(.linear(duration: 0.1)) { progress = Double(i) / 40 }
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
            }
            go(item)
        }
    }

    private var receding: Bool {
        stage == .shrink || stage == .black
    }

    private func respring(then next: Interaction?) {
        guard stage == .idle else { return }
        cancelAll()
        popup = nil
        afterRespring = next
        respringTask = Task { @MainActor in
            withAnimation(.easeIn(duration: 0.4)) { stage = .shrink }
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.3)) { stage = .black }
            let wait = max(0.3, respringTime)
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            if Task.isCancelled { return }
            if respringLock {
                withAnimation(.easeOut(duration: 0.55)) { stage = .lock }
            } else {
                unlock()
            }
        }
    }

    private func unlock() {
        let next = afterRespring
        afterRespring = nil
        if next == nil || next?.action == .restart {
            restart()
        } else {
            schedule()
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { stage = .idle }
        if let next = next, next.action != .restart {
            DispatchQueue.main.async { run(next) }
        }
    }

    private func cancelAll() {
        loading?.cancel()
        timers.forEach { $0.cancel() }
        timers = []
    }

    private func restart() {
        cancelAll()
        history = []
        switches = []
        visibility = [:]
        replays = [:]
        sliders = [:]
        tabChoice = [:]
        colors = [:]
        inks = [:]
        texts = [:]
        popup = nil
        progress = 0
        transition = .instant
        layer = UUID()
        current = project.frames.first?.id
        visit += 1
        DispatchQueue.main.async { schedule() }
    }
}
