import SwiftUI
import UIKit

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
    .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink, .brown, .clear
]

enum Kind: String, Codable, CaseIterable, Identifiable {
    case rect = "Rectangle"
    case circle = "Ellipse"
    case text = "Text"
    case button = "Button"
    case row = "Settings Row"
    case toggle = "Toggle"
    case progress = "Progress Bar"
    case console = "Console"
    var id: String { rawValue }
}

enum TapAction: String, Codable, CaseIterable, Identifiable {
    case none = "Nothing"
    case goTo = "Go to screen"
    case back = "Go back"
    case popup = "Show popup"
    case load = "Fill progress bars"
    case respring = "Respring"
    var id: String { rawValue }
}

struct Element: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: Kind
    var x: Double = 195
    var y: Double = 422
    var w: Double = 200
    var h: Double = 60
    var text = ""
    var fill = 10
    var ink = 4
    var radius: Double = 12
    var fontSize: Double = 17
    var opacity: Double = 1
    var action: TapAction = .none
    var target: UUID?
    var popupTitle = "Alert"
    var popupText = "Something happened."
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
        go.action = .load
        go.target = done.id
        home.elements = [title, logo, bar, go]

        var ok = makeElement(.text)
        ok.text = "Jailbroken"; ok.y = 120; ok.w = 340; ok.ink = 8; ok.fontSize = 40
        var log = makeElement(.console)
        log.y = 330
        var row = makeElement(.row)
        row.y = 530
        row.action = .popup
        row.popupTitle = "Tweaks"
        row.popupText = "No tweaks installed yet."
        var spring = makeElement(.button)
        spring.text = "Respring"; spring.y = 640; spring.w = 280; spring.action = .respring
        var back = makeElement(.button)
        back.text = "Back"; back.y = 720; back.w = 280; back.fill = 2; back.action = .back
        done.elements = [ok, log, row, spring, back]

        return Project(name: "Jailbreak Starter", frames: [home, done])
    }

    static func terminal() -> Project {
        var screen = Frame(name: "Shell")
        var log = makeElement(.console)
        log.y = 360; log.h = 520
        var run = makeElement(.button)
        run.text = "Run"; run.y = 700; run.fill = 8; run.ink = 0
        run.action = .popup
        run.popupTitle = "Shell"
        run.popupText = "Command finished."
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
    private let key = "fijistudio.projects"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([Project].self, from: data) {
            projects = list
        } else {
            projects = [Templates.jailbreak()]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: key)
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

struct RootView: View {
    @EnvironmentObject var store: Store
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

    var body: some View {
        NavigationStack {
            List {
                Section("New file") {
                    Button("Blank design") { create(Templates.blank()) }
                    Button("Template: Jailbreak Starter") { create(Templates.jailbreak()) }
                    Button("Template: Hacker Console") { create(Templates.terminal()) }
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
        if let string = UIPasteboard.general.string,
           let data = string.data(using: .utf8),
           var project = try? JSONDecoder().decode(Project.self, from: data),
           !project.frames.isEmpty {
            project.id = UUID()
            store.add(project)
            show("Imported \(project.name)")
        } else {
            show("No design found on the clipboard")
        }
    }

    private func show(_ text: String) {
        message = text
        showMessage = true
    }
}

struct Thumbnail: View {
    let frame: Frame
    var body: some View {
        ZStack {
            palette[frame.fill]
            ForEach(frame.elements) { element in
                ElementView(element: element)
                    .position(x: element.x, y: element.y)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
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
            .opacity(element.opacity)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: element.radius, style: .continuous)
    }

    private var font: Font {
        .system(size: element.fontSize, weight: .semibold, design: .rounded)
    }

    @ViewBuilder private var content: some View {
        switch element.kind {
        case .rect:
            shape.fill(palette[element.fill])
        case .circle:
            Ellipse().fill(palette[element.fill])
        case .text, .button:
            Text(element.text)
                .font(font)
                .multilineTextAlignment(.center)
                .foregroundColor(palette[element.ink])
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(shape.fill(palette[element.fill]))
        case .row:
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.orange)
                    .frame(width: 30, height: 30)
                    .overlay(Text(String(element.text.prefix(2))).font(.caption.bold()))
                Text(element.text).font(font).foregroundColor(palette[element.ink])
                Spacer()
                Text(">").foregroundColor(.gray)
            }
            .padding(.horizontal, 14)
            .frame(maxHeight: .infinity)
            .background(shape.fill(palette[element.fill]))
        case .toggle:
            HStack {
                Text(element.text).font(font).foregroundColor(palette[element.ink])
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
            .background(shape.fill(palette[element.fill]))
        case .progress:
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(white: 0.3))
                    Capsule()
                        .fill(palette[element.fill])
                        .frame(width: geo.size.width * progress)
                }
            }
        case .console:
            Text(visibleText)
                .font(.system(size: element.fontSize, design: .monospaced))
                .foregroundColor(palette[element.ink])
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(shape.fill(palette[element.fill]))
                .clipped()
        }
    }

    private var visibleText: String {
        guard let count = lines else { return element.text }
        let all = element.text.components(separatedBy: "\n")
        return all.prefix(count).joined(separator: "\n")
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
        copy.x += 16
        copy.y += 16
        frame.elements.append(copy)
        selected = copy.id
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
            for i in new.elements.indices { new.elements[i].id = UUID() }
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

    init(project: Project) {
        _model = StateObject(wrappedValue: EditorModel(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            frameTabs
            CanvasView(model: model, snap: snap)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(white: 0.08))
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
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button("Files") { store.editing = nil }
            Spacer()
            Text(model.project.name).bold().lineLimit(1)
            Spacer()
            Button("Undo") { model.undo() }.disabled(model.past.isEmpty)
            Button("Redo") { model.redo() }.disabled(model.future.isEmpty)
            Button("Play") {
                store.update(model.project)
                store.play(model.project.id, from: model.frame.id)
            }
            .buttonStyle(.borderedProminent)
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.vertical, 8)
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
                ForEach(Kind.allCases) { kind in
                    Button(kind.rawValue) { model.add(kind) }
                }
            }
            Spacer()
            Button("Layers") { panel = .layers }
            Spacer()
            Button("Screen") { model.checkpoint(); panel = .screen }
            Spacer()
            Button(snap ? "Snap On" : "Snap Off") { snap.toggle() }
        }
        .padding()
        .background(Color(white: 0.17))
    }
}

struct CanvasView: View {
    @ObservedObject var model: EditorModel
    let snap: Bool
    @State private var origin: CGPoint?

    var body: some View {
        GeometryReader { geo in
            let scale = max(0.1, min((geo.size.width - 24) / canvasSize.width,
                                     (geo.size.height - 16) / canvasSize.height))
            ZStack {
                palette[model.frame.fill]
                    .onTapGesture { model.selected = nil }
                ForEach(model.frame.elements) { element in
                    item(element)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .coordinateSpace(name: "canvas")
            .clipped()
            .border(Color.gray.opacity(0.5))
            .scaleEffect(scale)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .clipped()
    }

    private func item(_ element: Element) -> some View {
        ElementView(element: element)
            .contentShape(Rectangle())
            .overlay {
                if model.selected == element.id {
                    Rectangle().stroke(Color.cyan, lineWidth: 3)
                }
            }
            .onTapGesture { model.selected = element.id }
            .gesture(drag(element))
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
                        .overlay(Text(i == palette.count - 1 ? "none" : "").font(.system(size: 9)))
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
            if e.wrappedValue.kind != .rect && e.wrappedValue.kind != .circle
                && e.wrappedValue.kind != .progress {
                Section("Text") {
                    TextField("Text", text: e.text, axis: .vertical)
                    SliderRow(title: "Font size", value: e.fontSize, range: 8...72)
                    Swatches(title: "Text colour", selection: e.ink)
                }
            }
            Section("Layout") {
                SliderRow(title: "X", value: e.x, range: 0...390)
                SliderRow(title: "Y", value: e.y, range: 0...844)
                SliderRow(title: "Width", value: e.w, range: 10...390)
                SliderRow(title: "Height", value: e.h, range: 4...844)
            }
            Section("Style") {
                Swatches(title: "Fill", selection: e.fill)
                SliderRow(title: "Corner radius", value: e.radius, range: 0...80)
                SliderRow(title: "Opacity", value: e.opacity, range: 0.05...1, step: 0.05)
            }
            Section("Prototype: on tap") {
                Picker("Action", selection: e.action) {
                    ForEach(TapAction.allCases) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                if e.wrappedValue.action == .goTo || e.wrappedValue.action == .load {
                    Picker("Destination", selection: e.target) {
                        Text("None").tag(UUID?.none)
                        ForEach(model.project.frames) { frame in
                            Text(frame.name).tag(Optional(frame.id))
                        }
                    }
                }
                if e.wrappedValue.action == .popup {
                    TextField("Popup title", text: e.popupTitle)
                    TextField("Popup message", text: e.popupText, axis: .vertical)
                }
            }
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
                            Text(element.kind.rawValue)
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

struct PlayerView: View {
    @EnvironmentObject var store: Store
    let project: Project
    let start: UUID?

    @State private var current: UUID?
    @State private var history: [UUID] = []
    @State private var progress = 0.0
    @State private var loading: Task<Void, Never>?
    @State private var switches: Set<UUID> = []
    @State private var lines = 0
    @State private var popup: Element?
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
                palette[frame.fill == 15 ? 0 : frame.fill]
                ZStack {
                    ForEach(frame.elements) { element in
                        playable(element)
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(scale)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                if hint {
                    VStack {
                        Spacer()
                        Text("Press and hold to exit")
                            .font(.footnote)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(.bottom, 30)
                    }
                    .allowsHitTesting(false)
                }
                if respringing {
                    Color.black
                    ProgressView().tint(.white).scaleEffect(1.6)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(LongPressGesture(minimumDuration: 1.2).onEnded { _ in menu = true })
        }
        .background(Color.black)
        .ignoresSafeArea()
        .task(id: frame.id) { await typeLines() }
        .task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            hint = false
        }
        .onDisappear { loading?.cancel() }
        .alert(popup?.popupTitle ?? "", isPresented: Binding(
            get: { popup != nil },
            set: { if !$0 { popup = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(popup?.popupText ?? "")
        }
        .confirmationDialog("Prototype", isPresented: $menu) {
            Button("Restart") { restart() }
            Button("Exit prototype", role: .destructive) { store.playing = nil }
        }
    }

    private func playable(_ element: Element) -> some View {
        ElementView(element: element, progress: progress,
                    isOn: switches.contains(element.id), lines: lines)
            .contentShape(Rectangle())
            .onTapGesture { tap(element) }
            .position(x: element.x, y: element.y)
    }

    private func typeLines() async {
        lines = 0
        let counts = frame.elements.filter { $0.kind == .console }
            .map { $0.text.components(separatedBy: "\n").count }
        let total = counts.max() ?? 0
        while lines < total {
            try? await Task.sleep(nanoseconds: 450_000_000)
            if Task.isCancelled { return }
            lines += 1
        }
    }

    private func tap(_ element: Element) {
        if element.kind == .toggle {
            if switches.contains(element.id) { switches.remove(element.id) }
            else { switches.insert(element.id) }
        }
        switch element.action {
        case .none:
            break
        case .goTo:
            if let target = element.target { go(target) }
        case .back:
            if let last = history.popLast() {
                loading?.cancel()
                progress = 0
                current = last
            }
        case .popup:
            popup = element
        case .load:
            load(then: element.target)
        case .respring:
            respring()
        }
    }

    private func go(_ id: UUID) {
        guard project.frames.contains(where: { $0.id == id }) else { return }
        loading?.cancel()
        history.append(frame.id)
        progress = 0
        current = id
    }

    private func load(then target: UUID?) {
        loading?.cancel()
        loading = Task { @MainActor in
            for i in 0...40 {
                progress = Double(i) / 40
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
            }
            if let target = target { go(target) }
        }
    }

    private func respring() {
        respringing = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            respringing = false
            restart()
        }
    }

    private func restart() {
        loading?.cancel()
        history = []
        switches = []
        progress = 0
        current = project.frames.first?.id
    }
}
