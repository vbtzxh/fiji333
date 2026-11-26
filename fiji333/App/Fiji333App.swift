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
    var id: String { rawValue }

    var needsScreen: Bool { self == .goTo || self == .load }
    var needsLayer: Bool {
        self == .show || self == .hide || self == .toggleLayer || self == .animate
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

    var label: String { name.isEmpty ? kind.rawValue : name }

    enum CodingKeys: String, CodingKey {
        case id, link, kind, name, x, y, w, h, text, fill, fill2, ink, stroke, strokeWidth
        case radius, fontSize, weight, align, opacity, rotation, shadow, locked, hidden
        case image, imageFit, motion, motionEasing, motionTime, motionDelay, interactions
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
    @State private var importing = false
    @State private var exporting = false
    @State private var document = DataDocument(data: Data())
    @State private var filename = "design"

    var body: some View {
        NavigationStack {
            List {
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
            .navigationTitle("Fiji Studio")
            .toolbar {
                Button("About") { showAbout = true }
            }
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

    @ViewBuilder private var content: some View {
        switch element.kind {
        case .rect:
            shape.fill(paint)
        case .circle:
            Ellipse().fill(paint)
        case .image:
            picture
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
        return all.prefix(count).joined(separator: "\n")
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
                    if let old = new.elements[i].interactions[j].layer {
                        new.elements[i].interactions[j].layer = ids[old]
                    }
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
    case design, layers, screen
    var id: String { rawValue }
}

struct EditorView: View {
    @EnvironmentObject var store: Store
    @StateObject private var model: EditorModel
    @State private var panel: Panel?
    @State private var snap = true
    @State private var grid = false
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
                .background(Color(white: 0.08))
                .fileImporter(isPresented: $importingImage, allowedContentTypes: [.image]) { result in
                    if case .success(let url) = result, let data = readFile(url) {
                        model.addImage(data)
                    }
                }
            if model.selected != nil {
                selectionBar
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
                }
            }
            .presentationDetents([.medium, .large])
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
            Button("Screen") { model.checkpoint(); panel = .screen }
            Spacer()
            Menu("View") {
                Toggle("Snap", isOn: $snap)
                Toggle("Grid", isOn: $grid)
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
    @State private var origin: CGPoint?
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
            for x in stride(from: CGFloat(15), to: canvasSize.width, by: 30) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
            }
            for y in stride(from: CGFloat(32), to: canvasSize.height, by: 30) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
            }
        }
        .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
        .allowsHitTesting(false)
    }

    private var zoomButtons: some View {
        HStack {
            Button("-") { zoom = max(0.4, zoom / 1.25) }
            Button("Fit") { zoom = 1; pan = .zero }
            Button("+") { zoom = min(5, zoom * 1.25) }
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
            .onEnded { value in zoom = min(5, max(0.4, zoom * value)) }
    }

    private func item(_ element: Element) -> some View {
        ElementView(element: element)
            .opacity(element.hidden ? 0.25 : 1)
            .contentShape(Rectangle())
            .overlay {
                if model.selected == element.id {
                    Rectangle().stroke(Color.cyan, lineWidth: 3)
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
                    x = (x / 5).rounded() * 5
                    y = (y / 5).rounded() * 5
                    if abs(x - 195) < 10 { x = 195 }
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

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title): \(String(format: step < 1 ? "%.2f" : "%.0f", value))")
            HStack {
                Button("-") { value = max(range.lowerBound, value - step) }
                    .buttonStyle(.bordered)
                Slider(value: $value, in: range)
                Button("+") { value = min(range.upperBound, value + step) }
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

    private func hasText(_ kind: Kind) -> Bool {
        kind == .text || kind == .button || kind == .row || kind == .toggle || kind == .console
    }

    private func textSection(_ e: Binding<Element>) -> some View {
        Section("Text") {
            TextField("Text", text: e.text, axis: .vertical)
            SliderRow(title: "Font size", value: e.fontSize, range: 8...96)
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
            SliderRow(title: "X", value: e.x, range: 0...390)
            SliderRow(title: "Y", value: e.y, range: 0...844)
            SliderRow(title: "Width", value: e.w, range: 4...390)
            SliderRow(title: "Height", value: e.h, range: 4...844)
            SliderRow(title: "Rotation", value: e.rotation, range: -180...180)
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
            SliderRow(title: "Corner radius", value: e.radius, range: 0...200)
            SliderRow(title: "Opacity", value: e.opacity, range: 0.05...1, step: 0.05)
            SliderRow(title: "Shadow", value: e.shadow, range: 0...40)
            SliderRow(title: "Border width", value: e.strokeWidth, range: 0...20)
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
            SliderRow(title: "Duration (s)", value: $element.motionTime, range: 0.1...4, step: 0.1)
            SliderRow(title: "Delay (s)", value: $element.motionDelay, range: 0...10, step: 0.1)
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

struct InteractionEditor: View {
    @ObservedObject var model: EditorModel
    @Binding var item: Interaction

    var body: some View {
        Group {
            Picker("Trigger", selection: $item.trigger) {
                ForEach(Trigger.allCases) { Text($0.rawValue).tag($0) }
            }
            if item.trigger == .delay {
                SliderRow(title: "Wait (s)", value: $item.wait, range: 0.1...30, step: 0.1)
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
            SliderRow(title: "Duration (s)", value: $item.duration, range: 0.1...2, step: 0.05)
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
        if item.action == .popup {
            TextField("Popup title", text: $item.title)
            TextField("Popup message", text: $item.message, axis: .vertical)
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
    @State private var lines = 0
    @State private var popup: Interaction?
    @State private var respringing = false
    @State private var menu = false
    @State private var hint = true

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
                if hint { hintView }
                if respringing {
                    Color.black
                    ProgressView().tint(.white).scaleEffect(1.6)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(LongPressGesture(minimumDuration: 2).onEnded { _ in menu = true })
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear { schedule() }
        .task(id: visit) { await typeLines() }
        .task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            hint = false
        }
        .onDisappear { cancelAll() }
        .alert(popup?.title ?? "", isPresented: Binding(
            get: { popup != nil },
            set: { if !$0 { popup = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(popup?.message ?? "")
        }
        .confirmationDialog("Prototype", isPresented: $menu) {
            Button("Restart") { restart() }
            Button("Exit prototype", role: .destructive) { store.playing = nil }
        }
    }

    private var hintView: some View {
        VStack {
            Spacer()
            Text("Hold for 2 seconds to exit")
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
        return ElementView(element: element, progress: progress,
                           isOn: switches.contains(element.id), lines: lines)
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

    private func typeLines() async {
        lines = 0
        while !Task.isCancelled {
            let counts = frame.elements.filter { $0.kind == .console }
                .map { $0.text.components(separatedBy: "\n").count }
            if lines >= (counts.max() ?? 0) { return }
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }
            lines += 1
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
            popup = item
        case .load:
            load(item)
        case .respring:
            respring()
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .restart:
            restart()
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

    private func respring() {
        cancelAll()
        respringing = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            respringing = false
            restart()
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
        progress = 0
        transition = .instant
        layer = UUID()
        current = project.frames.first?.id
        visit += 1
        DispatchQueue.main.async { schedule() }
    }
}
