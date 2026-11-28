import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import AudioToolbox
import CoreMotion

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
    case clock = "Live Clock"
    case spinner = "Spinner"
    case ring = "Progress Ring"
    case appIcon = "App Icon"
    case statusBar = "OS Status Bar"
    case homeBar = "Home Bar"
    case notification = "Notification"
    case widget = "Date Widget"
    case calculator = "Calculator"
    case notes = "Notes Pad"
    case window = "Window"
    case shell = "Typing Terminal"
    case panel = "Taskbar / Panel"

    static let pcParts: [Kind] = [.window, .shell, .panel]

    static let osParts: [Kind] = [
        .appIcon, .statusBar, .homeBar, .notification, .widget, .calculator, .notes
    ]
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
    case shake = "Shake screen"
    case flash = "Flash screen"
    case burst = "Confetti burst"
    case particles = "Start / stop particles"
    case sound = "Play sound"
    case home = "Go to home screen"
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

enum EffectKind: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case rainbow = "Rainbow colours"
    case rainbowBorder = "Rainbow border"
    case rainbowGlow = "Rainbow glow"
    case hue = "Colour cycle"
    case glow = "Pulsing glow"
    case shimmer = "Shimmer"
    case glitch = "Glitch"
    case wobble = "Wobble"
    case breathe = "Breathe"
    case flicker = "Flicker"
    var id: String { rawValue }
}

enum SoundKind: Int, Codable, CaseIterable, Identifiable {
    case click = 1104
    case tink = 1057
    case chime = 1025
    case tweet = 1016
    case alert = 1005
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .click: return "Click"
        case .tink: return "Tink"
        case .chime: return "Chime"
        case .tweet: return "Tweet"
        case .alert: return "Alert"
        }
    }
}

enum ParticleShape: String, Codable, CaseIterable, Identifiable {
    case circle = "Circle"
    case square = "Square"
    case streak = "Streak"
    case star = "Star"
    case ring = "Bubble"
    case text = "Text or emoji"
    case image = "Your image"
    var id: String { rawValue }
}

struct Particles: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = "Custom"
    var shape: ParticleShape = .circle
    var symbol = "*"
    var image: Data?
    var colors: [Int] = [4]
    var rainbow = false
    var count: Double = 60
    var minSize: Double = 4
    var maxSize: Double = 10
    var speed: Double = 80
    var direction: Double = 0
    var wobble: Double = 10
    var spin: Double = 0
    var opacity: Double = 0.9
    var twinkle = false
    var front = true

    static let presetNames = ["Snow", "Rain", "Confetti", "Stars", "Matrix", "Bubbles",
                              "Embers", "Hearts", "Leaves", "Rainbow dust", "Custom"]

    static func preset(_ name: String) -> Particles {
        var p = Particles()
        p.name = name
        switch name {
        case "Snow":
            p.count = 90; p.speed = 50; p.wobble = 25
        case "Rain":
            p.shape = .streak; p.colors = [23]; p.count = 120; p.speed = 600
            p.wobble = 0; p.minSize = 10; p.maxSize = 24; p.direction = 8; p.opacity = 0.6
        case "Confetti":
            p.shape = .square; p.colors = [5, 7, 8, 10, 12, 13]; p.speed = 130
            p.spin = 180; p.minSize = 6; p.maxSize = 12
        case "Stars":
            p.shape = .star; p.colors = [4, 7]; p.speed = 4; p.twinkle = true
            p.front = false; p.minSize = 3; p.maxSize = 9
        case "Matrix":
            p.shape = .text; p.symbol = "01"; p.colors = [8, 21]; p.speed = 220
            p.wobble = 0; p.minSize = 12; p.maxSize = 20; p.front = false
        case "Bubbles":
            p.shape = .ring; p.colors = [23, 4]; p.direction = 180; p.speed = 60
            p.count = 35; p.minSize = 8; p.maxSize = 30
        case "Embers":
            p.colors = [5, 6, 7]; p.direction = 180; p.speed = 90; p.wobble = 20
            p.twinkle = true; p.minSize = 2; p.maxSize = 6
        case "Hearts":
            p.shape = .text; p.symbol = "\u{2665}"; p.colors = [5, 13]; p.direction = 180
            p.count = 30; p.minSize = 14; p.maxSize = 34
        case "Leaves":
            p.shape = .square; p.colors = [6, 14, 17]; p.count = 30; p.spin = 90
            p.wobble = 45; p.direction = 25; p.minSize = 8; p.maxSize = 16
        case "Rainbow dust":
            p.rainbow = true; p.speed = 35; p.wobble = 30; p.twinkle = true
            p.minSize = 3; p.maxSize = 8; p.count = 110
        default:
            break
        }
        return p
    }
}

enum PopupPlace: String, Codable, CaseIterable, Identifiable {
    case top = "Top"
    case middle = "Middle"
    case bottom = "Bottom"
    var id: String { rawValue }
}

enum PopupStyle: String, Codable, CaseIterable, Identifiable {
    case alert = "iOS alert"
    case sheet = "iOS action sheet"
    case custom = "Custom colours"
    var id: String { rawValue }
}

enum PopupRole: String, Codable, CaseIterable, Identifiable {
    case normal = "Normal"
    case cancel = "Cancel (bold)"
    case destructive = "Destructive (red)"
    var id: String { rawValue }
}

struct PopupButton: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = "OK"
    var fill = 10
    var ink = 4
    var role: PopupRole?
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
    var style: PopupStyle = .alert
    var sound: SoundKind = .chime
    // What happens after a respring. Empty means restart the prototype.
    var then: [Interaction] = []

    enum CodingKeys: String, CodingKey {
        case id, trigger, action, wait, screen, layer, title, message, transition, easing, duration
        case buttons, popupFill, popupInk, popupRadius, popupDim, popupPlace, popupStack
        case autoClose, color, colorText, newText, then, style, sound
    }

    // Points every nested action at new screen and layer ids after a merge.
    mutating func relink(layers: [UUID: UUID], screens: [UUID: UUID]) {
        if let old = layer { layer = layers[old] ?? old }
        if let old = screen { screen = screens[old] ?? old }
        for i in then.indices { then[i].relink(layers: layers, screens: screens) }
        for i in buttons.indices {
            for j in buttons[i].then.indices {
                buttons[i].then[j].relink(layers: layers, screens: screens)
            }
        }
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
        style = read(.style, style)
        sound = read(.sound, sound)
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
    var extra: [Int]?
    var angle: Double = 0
    var radial = false
    var effect: EffectKind = .none
    var effectSpeed: Double = 1
    var parent: UUID?
    var commands = ""
    var prompt = "$"
    var mono = false

    // Gradient colours after the main fill. Older designs only stored fill2.
    var moreColors: [Int] { extra ?? fill2.map { [$0] } ?? [] }

    var label: String { name.isEmpty ? kind.rawValue : name }

    enum CodingKeys: String, CodingKey {
        case id, link, kind, name, x, y, w, h, text, fill, fill2, ink, stroke, strokeWidth
        case radius, fontSize, weight, align, opacity, rotation, shadow, locked, hidden
        case image, imageFit, motion, motionEasing, motionTime, motionDelay, interactions
        case consoleSpeed, consoleWait, consoleLoop, consoleScroll
        case value, showValue, tabTargets
        case extra, angle, radial, effect, effectSpeed
        case parent, commands, prompt, mono
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
        extra = try? c.decode([Int].self, forKey: .extra)
        angle = read(.angle, angle)
        radial = read(.radial, radial)
        effect = read(.effect, effect)
        effectSpeed = read(.effectSpeed, effectSpeed)
        parent = try? c.decode(UUID.self, forKey: .parent)
        commands = read(.commands, commands)
        prompt = read(.prompt, prompt)
        mono = read(.mono, mono)

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
    var extra: [Int]?
    var angle: Double?
    var radial: Bool?
    var particles: [Particles]?
    var rainbow: Bool?
    var rainbowSpeed: Double?
    var isHome: Bool?
    var width: Double?
    var height: Double?

    // Screens without a stored size are phone sized.
    var size: CGSize {
        CGSize(width: max(100, width ?? Double(canvasSize.width)),
               height: max(100, height ?? Double(canvasSize.height)))
    }
    var w: Double { Double(size.width) }
    var h: Double { Double(size.height) }
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
    case .clock: e.w = 340; e.h = 100; e.fill = noColor; e.fontSize = 72; e.y = 180
    case .spinner: e.w = 80; e.h = 80; e.fill = 10
    case .ring: e.w = 160; e.h = 160; e.fill = 8; e.fontSize = 28
    case .appIcon:
        e.text = "App"; e.w = 74; e.h = 94; e.radius = 18; e.fontSize = 13
    case .statusBar:
        e.text = "TrollNet"; e.w = 370; e.h = 28; e.y = 22; e.fill = noColor
        e.fontSize = 15; e.value = 0.8
    case .homeBar:
        e.w = 150; e.h = 28; e.y = 826; e.fill = 4
        var swipe = Interaction(action: .home)
        swipe.trigger = .swipeUp
        e.interactions = [swipe, Interaction(action: .home)]
    case .notification:
        e.text = "Messages\nYou have been trolled."; e.w = 360; e.h = 84; e.y = 110
        e.fill = 2; e.radius = 22; e.fontSize = 15
    case .widget:
        e.w = 170; e.h = 170; e.fill = 1; e.radius = 28; e.fontSize = 56
    case .window:
        e.text = "Window"; e.w = 460; e.h = 300; e.fill = 1; e.radius = 10; e.fontSize = 15
    case .shell:
        e.text = "Type help and press return"; e.w = 440; e.h = 260; e.fill = 0; e.ink = 8
        e.radius = 6; e.fontSize = 14; e.prompt = "$"
    case .panel:
        e.text = "Menu\nFiles\nTerminal"; e.w = 390; e.h = 40; e.fill = 1; e.radius = 0
        e.fontSize = 15
    case .calculator: e.w = 340; e.h = 460; e.fill = 1; e.radius = 24; e.fontSize = 28
    case .notes:
        e.text = "Write something..."; e.w = 350; e.h = 460; e.fill = 1; e.fontSize = 17
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

// Fits a new layer to the size of the screen it is added to.
func fitted(_ element: Element, on screen: Frame) -> Element {
    var e = element
    e.x = screen.w / 2
    e.y = screen.h / 2
    e.w = min(e.w, screen.w)
    e.h = min(e.h, screen.h)
    switch e.kind {
    case .statusBar: e.y = 22; e.w = screen.w - 20
    case .homeBar: e.y = screen.h - 18
    case .panel: e.w = screen.w; e.y = screen.h - e.h / 2
    case .tabs: e.y = screen.h - 64
    default: break
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

    static func random(name: String) -> Project {
        let title = name.isEmpty ? "fiji333" : name
        let colors = [0, 29, 24, 25, 17, 21, 30, 11]
        let accent = [5, 6, 8, 10, 12, 13, 23].randomElement() ?? 10
        let weather = ["Snow", "Rain", "Stars", "Matrix", "Embers", "Rainbow dust",
                       "Bubbles"].randomElement() ?? "Stars"
        var home = Frame(name: "Home")
        var done = Frame(name: "Done")
        for index in 0..<2 {
            var screen = index == 0 ? home : done
            screen.fill = colors.randomElement() ?? 0
            screen.extra = [colors.randomElement() ?? 29]
            screen.angle = Double([0, 45, 90, 135].randomElement() ?? 0)
            screen.particles = [Particles.preset(weather)]
            if index == 0 { home = screen } else { done = screen }
        }

        var heading = makeElement(.text)
        heading.text = title; heading.y = 160; heading.w = 370; heading.fontSize = 52
        heading.effect = [.rainbow, .glow, .glitch, .breathe].randomElement() ?? .glow
        var ring = makeElement(.ring)
        ring.y = 390; ring.fill = accent
        var start = makeElement(.button)
        start.text = ["Jailbreak", "Start", "Unlock", "Go"].randomElement() ?? "Start"
        start.y = 650; start.w = 280; start.fill = accent
        start.radius = Double([8, 16, 30].randomElement() ?? 16)
        start.interactions = [Interaction(action: .load, screen: done.id)]
        home.elements = [heading, ring, start]

        var message = makeElement(.text)
        message.text = "Done!"; message.y = 150; message.w = 340; message.fontSize = 56
        message.motion = .pop
        var log = makeElement(.console)
        log.y = 390
        log.text = "[*] \(title)\n[+] warming up\n[+] adding \(weather.lowercased())\n[*] complete"
        var again = makeElement(.button)
        again.text = "Respring"; again.y = 650; again.w = 280; again.fill = accent
        again.interactions = [Interaction(action: .respring)]
        var party = Interaction(action: .burst)
        party.trigger = .delay
        party.wait = 0.4
        message.interactions = [party]
        done.elements = [message, log, again]
        return Project(name: title, frames: [home, done])
    }

    static func party() -> Project {
        var screen = Frame(name: "Party")
        screen.fill = 29
        screen.extra = [25]
        screen.particles = [Particles.preset("Stars"), Particles.preset("Snow")]
        var title = makeElement(.text)
        title.text = "fiji333"; title.y = 250; title.w = 360; title.fontSize = 64
        title.effect = .rainbow
        var ring = makeElement(.spinner)
        ring.y = 420
        var button = makeElement(.button)
        button.text = "Party"; button.y = 640; button.w = 260
        button.effect = .rainbowBorder
        button.interactions = [Interaction(action: .burst)]
        screen.elements = [title, ring, button]
        return Project(name: "Rainbow Party", frames: [screen])
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

    private var written: [UUID: Project] = [:]
    @Published var lastSaved: Date?
    @Published var saveProblem: String?

    init() {
        Vault.prepare()
        let saved = (try? Data(contentsOf: Vault.library))
            ?? UserDefaults.standard.data(forKey: oldKey)
        if let data = saved,
           let list = try? JSONDecoder().decode([Project].self, from: data) {
            projects = list
            Vault.backup(data)
        } else {
            if let data = saved {
                Vault.backup(data, label: "unreadable")
            }
            let recovered = Vault.recover()
            projects = recovered.isEmpty ? [Templates.jailbreak()] : recovered
        }
        flush()
    }

    private func save() {
        pending?.cancel()
        pending = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            if Task.isCancelled { return }
            flush()
        }
    }

    func flush() {
        pending?.cancel()
        do {
            Vault.prepare()
            let data = try JSONEncoder().encode(projects)
            try data.write(to: Vault.library, options: .atomic)
            // One readable file per design, rewritten only when it changes.
            for project in projects where written[project.id] != project {
                try Vault.mirror(project)
                written[project.id] = project
            }
            let alive = Set(projects.map { $0.id })
            for id in Array(written.keys) where !alive.contains(id) {
                Vault.removeMirror(id)
                written[id] = nil
            }
            lastSaved = Date()
            saveProblem = nil
        } catch {
            saveProblem = error.localizedDescription
        }
    }

    func backupNow() -> Bool {
        flush()
        guard let data = try? Data(contentsOf: Vault.library) else { return false }
        return Vault.backup(data, label: "manual")
    }

    // Adds designs from a design file or a whole library file.
    func importData(_ data: Data) -> Int {
        var found: [Project] = []
        if let one = try? JSONDecoder().decode(Project.self, from: data) {
            found = [one]
        } else if let many = try? JSONDecoder().decode([Project].self, from: data) {
            found = many
        }
        found = found.filter { !$0.frames.isEmpty }
        for var project in found {
            project.id = UUID()
            add(project)
        }
        return found.count
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

// MARK: - Files on the phone

// Everything lives in the app's Documents folder, visible in the Files app.
enum Vault {
    static var root: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var library: URL { root.appendingPathComponent("fijistudio.json") }
    static var autosave: URL { root.appendingPathComponent("Autosave", isDirectory: true) }
    static var backups: URL { root.appendingPathComponent("Backups", isDirectory: true) }

    static func prepare() {
        for folder in [autosave, backups] {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let note = root.appendingPathComponent("READ ME.txt")
        if !FileManager.default.fileExists(atPath: note.path) {
            let text = """
            Autosave: one file for each design.
            Backups: older copies of all your designs.
            fijistudio.json: the main save. Do not rename it.
            """
            try? text.write(to: note, atomically: true, encoding: .utf8)
        }
    }

    static func safeName(_ name: String) -> String {
        let bad = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.newlines)
        let clean = name.components(separatedBy: bad).joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ."))
        return clean.isEmpty ? "design" : String(clean.prefix(60))
    }

    static func files(in folder: URL) -> [URL] {
        let list = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil)) ?? []
        return list.filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private static func tag(_ id: UUID) -> String {
        "[" + String(id.uuidString.prefix(8)) + "].json"
    }

    static func removeMirror(_ id: UUID) {
        for file in files(in: autosave) where file.lastPathComponent.hasSuffix(tag(id)) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    static func mirror(_ project: Project) throws {
        let name = safeName(project.name) + " " + tag(project.id)
        let target = autosave.appendingPathComponent(name)
        let data = try JSONEncoder().encode(project)
        try data.write(to: target, options: .atomic)
        // Remove the copy saved under an older name.
        for file in files(in: autosave)
        where file.lastPathComponent.hasSuffix(tag(project.id)) && file.lastPathComponent != name {
            try? FileManager.default.removeItem(at: file)
        }
    }

    static func recover() -> [Project] {
        files(in: autosave).compactMap { file in
            guard let data = try? Data(contentsOf: file) else { return nil }
            return try? JSONDecoder().decode(Project.self, from: data)
        }
    }

    // Keeps the 15 newest backups.
    @discardableResult
    static func backup(_ data: Data, label: String = "auto") -> Bool {
        prepare()
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_US_POSIX")
        format.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let target = backups.appendingPathComponent("\(format.string(from: Date())) \(label).json")
        guard (try? data.write(to: target, options: .atomic)) != nil else { return false }
        for old in files(in: backups).dropFirst(15) {
            try? FileManager.default.removeItem(at: old)
        }
        return true
    }
}

// The system document picker, shown from whatever screen is on top.
@MainActor
final class FilePicker: NSObject, UIDocumentPickerDelegate {
    private static var current: FilePicker?
    private let done: (URL?) -> Void

    private init(done: @escaping (URL?) -> Void) {
        self.done = done
    }

    static func open(_ types: [UTType], done: @escaping (Data) -> Void) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        present(picker) { url in
            if let url = url, let data = readFile(url) { done(data) }
        }
    }

    static func save(_ data: Data, name: String, done: @escaping (Bool) -> Void = { _ in }) {
        guard let url = temporary(data, name: name) else {
            done(false)
            return
        }
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        present(picker) { saved in done(saved != nil) }
    }

    static func share(_ data: Data, name: String) {
        guard let url = temporary(data, name: name), let host = topController() else { return }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = host.view
        sheet.popoverPresentationController?.sourceRect = CGRect(
            x: host.view.bounds.midX, y: host.view.bounds.midY, width: 1, height: 1)
        host.present(sheet, animated: true)
    }

    private static func temporary(_ data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        guard (try? data.write(to: url, options: .atomic)) != nil else { return nil }
        return url
    }

    private static func present(_ picker: UIDocumentPickerViewController,
                                done: @escaping (URL?) -> Void) {
        // Wait briefly so a closing menu does not block the picker.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let host = topController() else { return }
            let delegate = FilePicker(done: done)
            current = delegate
            picker.delegate = delegate
            host.present(picker, animated: true)
        }
    }

    private static func topController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        var top = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
        while let next = top?.presentedViewController, !next.isBeingDismissed {
            top = next
        }
        return top
    }

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        done(urls.first)
        FilePicker.current = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        done(nil)
        FilePicker.current = nil
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
    @State private var showLabs = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Settings and slider limits") { showSettings = true }
                }
                Section("New file") {
                    Button("Blank design") { create(Templates.blank()) }
                    Button("Blank PC design") {
                        var screen = Frame(name: "Desktop")
                        screen.width = 960
                        screen.height = 540
                        create(Project(name: "My PC OS", frames: [screen]))
                    }
                    Button("Template: Jailbreak Starter") { create(Templates.jailbreak()) }
                    Button("Template: Hacker Console") { create(Templates.terminal()) }
                    Button("Template: Rainbow Party") { create(Templates.party()) }
                    Button("Open from Files") { openFile() }
                    Button("Import from clipboard") { importProject() }
                }
                Section {
                    Button("Experimental Labs") { showLabs = true }
                }
                Section("Saving") {
                    if let problem = store.saveProblem {
                        Text("Save failed: " + problem).foregroundColor(.red)
                    } else if let date = store.lastSaved {
                        Text("Autosaved at " + date.formatted(date: .omitted, time: .standard))
                    }
                    Text("Files app: On My iPhone, then fiji333")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Back up now") {
                        show(store.backupNow() ? "Backup saved" : "Backup failed")
                    }
                    Button("Save all designs to Files") { saveAll() }
                    NavigationLink("Restore a backup") { BackupsView() }
                }
                Section("Make an OS") {
                    Button("Template: TrollOS") { create(OSKit.trollOS()) }
                    Button("Blank OS (boot, lock, home)") { create(OSKit.blankOS()) }
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
            .background(Color.clear.sheet(isPresented: $showLabs) {
                LabsView().environmentObject(store)
            })
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
                Button("Save to Files") { saveFile(project) }
                Button("Share") { shareFile(project) }
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
        let count = data.map { store.importData($0) } ?? 0
        show(count > 0 ? "Imported \(count) design(s)" : "That is not a Fiji Studio design")
    }

    private func openFile() {
        FilePicker.open([.json, .text, .data]) { data in load(data) }
    }

    private func saveFile(_ project: Project) {
        guard let data = try? JSONEncoder().encode(project) else { return }
        FilePicker.save(data, name: Vault.safeName(project.name) + ".json") { saved in
            if saved { show("Saved to Files") }
        }
    }

    private func shareFile(_ project: Project) {
        guard let data = try? JSONEncoder().encode(project) else { return }
        FilePicker.share(data, name: Vault.safeName(project.name) + ".json")
    }

    private func saveAll() {
        guard let data = try? JSONEncoder().encode(store.projects) else { return }
        FilePicker.save(data, name: "All designs.json") { saved in
            if saved { show("Saved to Files") }
        }
    }

    private func show(_ text: String) {
        message = text
        showMessage = true
    }
}

func makePaint(_ colors: [Int], angle: Double, radial: Bool, reach: Double) -> AnyShapeStyle {
    var list = colors.map { swatch($0) }
    if list.count == 1 { list.append(list[0]) }
    let gradient = Gradient(colors: list)
    if radial {
        return AnyShapeStyle(RadialGradient(gradient: gradient, center: .center,
                                            startRadius: 0, endRadius: max(1, reach)))
    }
    // 0 degrees runs from top to bottom.
    let turn = angle * Double.pi / 180
    let dx = sin(turn) * 0.5
    let dy = cos(turn) * 0.5
    return AnyShapeStyle(LinearGradient(gradient: gradient,
                                        startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
                                        endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy)))
}

struct Backdrop: View {
    let screen: Frame
    var animated = true

    private var colors: [Int] {
        let all = [screen.fill] + (screen.extra ?? [])
        return all == [noColor] ? [0] : all
    }

    var body: some View {
        if animated && (screen.rainbow ?? false) {
            TimelineView(.animation) { context in
                let speed = screen.rainbowSpeed ?? 1
                let t = context.date.timeIntervalSinceReferenceDate * speed
                base.hueRotation(.degrees(t.truncatingRemainder(dividingBy: 8) * 45))
            }
        } else {
            base
        }
    }

    // A rainbow needs a colourful base for the hue to move.
    private var base: some View {
        let list = (screen.rainbow ?? false) && colors.count == 1 ? [5, 12, 10] : colors
        return Rectangle()
            .fill(makePaint(list, angle: screen.angle ?? 0,
                            radial: screen.radial ?? false, reach: 500))
    }
}

struct GradientEditor: View {
    @Binding var fill: Int
    @Binding var extra: [Int]
    @Binding var angle: Double
    @Binding var radial: Bool

    private let presets: [(String, [Int])] = [
        ("Sunset", [12, 13, 6]), ("Ocean", [24, 10, 23]), ("Neon", [26, 12, 23]),
        ("Matrix", [0, 21, 8]), ("Fire", [17, 5, 6, 7]), ("Rainbow", [5, 6, 7, 8, 10, 12])
    ]

    var body: some View {
        Group {
            Rectangle()
                .fill(makePaint([fill] + extra, angle: angle, radial: radial, reach: 180))
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Swatches(title: extra.isEmpty ? "Colour" : "Colour 1", selection: $fill)
            ForEach(extra.indices, id: \.self) { i in
                VStack(alignment: .leading) {
                    Swatches(title: "Colour \(i + 2)", selection: color(i))
                    Button("Remove colour \(i + 2)", role: .destructive) { remove(i) }
                        .buttonStyle(.borderless)
                }
            }
            Button("+ Add gradient colour") {
                extra.append(extra.count % 2 == 0 ? 12 : 10)
            }
            Menu("Gradient presets") {
                ForEach(presets, id: \.0) { preset in
                    Button(preset.0) { use(preset.1) }
                }
            }
            if !extra.isEmpty {
                Button("Reverse colours") { use(([fill] + extra).reversed()) }
                Toggle("Circular gradient", isOn: $radial)
                if !radial {
                    SliderRow(title: "Angle", value: $angle, range: 0...360, step: 15)
                }
            }
        }
    }

    private func color(_ index: Int) -> Binding<Int> {
        Binding(
            get: { extra.indices.contains(index) ? extra[index] : fill },
            set: { if extra.indices.contains(index) { extra[index] = $0 } }
        )
    }

    private func remove(_ index: Int) {
        if extra.indices.contains(index) { extra.remove(at: index) }
    }

    private func use(_ colors: [Int]) {
        guard let first = colors.first else { return }
        fill = first
        extra = Array(colors.dropFirst())
    }
}

// MARK: - Effects

let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]

struct Effects: ViewModifier {
    let element: Element
    var active = true

    func body(content: Content) -> some View {
        if element.effect == .none || !active {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                apply(content, context.date.timeIntervalSinceReferenceDate * element.effectSpeed)
            }
        }
    }

    private var corner: RoundedRectangle {
        RoundedRectangle(cornerRadius: element.radius, style: .continuous)
    }

    @ViewBuilder private func apply(_ content: Content, _ t: Double) -> some View {
        let cycle = t.truncatingRemainder(dividingBy: 4) / 4
        let wave = (sin(t * 3) + 1) / 2
        switch element.effect {
        case .none:
            content
        case .rainbow:
            content.overlay(
                AngularGradient(colors: rainbowColors, center: .center,
                                angle: .degrees(cycle * 360))
                    .mask(content)
                    .allowsHitTesting(false)
            )
        case .rainbowBorder:
            content.overlay(
                corner.stroke(AngularGradient(colors: rainbowColors, center: .center,
                                              angle: .degrees(cycle * 360)), lineWidth: 5)
                    .frame(width: element.w, height: element.h)
                    .rotationEffect(.degrees(element.rotation))
                    .allowsHitTesting(false)
            )
        case .rainbowGlow:
            content.shadow(color: Color(hue: cycle, saturation: 1, brightness: 1), radius: 22)
        case .hue:
            content.hueRotation(.degrees(cycle * 360))
        case .glow:
            content.shadow(color: Color.white.opacity(wave), radius: 6 + 20 * wave)
        case .shimmer:
            content.overlay(
                LinearGradient(colors: [.clear, Color.white.opacity(0.8), .clear],
                               startPoint: UnitPoint(x: cycle * 3 - 1, y: 0),
                               endPoint: UnitPoint(x: cycle * 3, y: 1))
                    .mask(content)
                    .allowsHitTesting(false)
            )
        case .glitch:
            let jump = sin(t * 13) > 0.7
            content
                .offset(x: jump ? sin(t * 97) * 10 : 0)
                .hueRotation(.degrees(jump ? 120 : 0))
        case .wobble:
            content.rotationEffect(.degrees(sin(t * 4) * 5))
        case .breathe:
            content.scaleEffect(0.95 + 0.1 * wave)
        case .flicker:
            content.opacity(sin(t * 23) * sin(t * 7) > 0.3 ? 0.25 : 1)
        }
    }
}

// A repeatable pseudo random number from 0 to 1.
func noise(_ index: Int, _ salt: Int) -> Double {
    let value = sin(Double(index) * 12.9898 + Double(salt) * 78.233) * 43758.5453
    return value - value.rounded(.down)
}

func wrap(_ value: Double, _ length: Double) -> Double {
    let rest = value.truncatingRemainder(dividingBy: length)
    return rest < 0 ? rest + length : rest
}

func starPath(_ size: Double) -> Path {
    var path = Path()
    for i in 0..<10 {
        let reach = i % 2 == 0 ? size / 2 : size / 4.5
        let turn = Double(i) * Double.pi / 5
        let point = CGPoint(x: sin(turn) * reach, y: -cos(turn) * reach)
        if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
}

struct ParticleField: View {
    let systems: [Particles]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 100_000)
                for system in systems {
                    draw(system, in: context, size: size, time: time)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ p: Particles, in context: GraphicsContext, size: CGSize, time: Double) {
        let total = min(1500, max(0, Int(p.count)))
        let margin = max(p.minSize, p.maxSize) + abs(p.wobble)
        let width = Double(size.width) + margin * 2
        let height = Double(size.height) + margin * 2
        let turn = p.direction * Double.pi / 180
        let picture = p.image.flatMap { cachedImage($0) }

        for i in 0..<total {
            let pace = p.speed * (0.6 + 0.8 * noise(i, 3))
            let sway = sin(time * 2 + noise(i, 4) * 6.28) * p.wobble
            let x = wrap(noise(i, 1) * width - sin(turn) * pace * time, width) - margin + sway
            let y = wrap(noise(i, 2) * height + cos(turn) * pace * time, height) - margin
            let low = min(p.minSize, p.maxSize)
            let side = max(1, low + noise(i, 5) * abs(p.maxSize - p.minSize))

            let color: Color
            if p.rainbow || p.colors.isEmpty {
                color = Color(hue: wrap(noise(i, 6) + time * 0.15, 1),
                              saturation: 0.85, brightness: 1)
            } else {
                color = swatch(p.colors[i % p.colors.count])
            }

            var layer = context
            let shine = p.twinkle ? (sin(time * 3 + noise(i, 7) * 6.28) + 1) / 2 : 1
            layer.opacity = p.opacity * shine
            layer.translateBy(x: x, y: y)
            let scatter: Double = p.spin == 0 ? 0 : noise(i, 9) * 360
            var angle: Double = p.spin * time * (noise(i, 8) * 2 - 1) + scatter
            if p.shape == .streak { angle = p.direction }
            layer.rotate(by: .degrees(angle))

            let box = CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
            switch p.shape {
            case .circle:
                layer.fill(Path(ellipseIn: box), with: .color(color))
            case .square:
                layer.fill(Path(CGRect(x: -side / 2, y: -side / 3, width: side, height: side / 1.5)),
                           with: .color(color))
            case .streak:
                layer.fill(Path(CGRect(x: -1, y: -side / 2, width: 2, height: side)),
                           with: .color(color))
            case .star:
                layer.fill(starPath(side), with: .color(color))
            case .ring:
                layer.stroke(Path(ellipseIn: box), with: .color(color), lineWidth: 1.5)
            case .text:
                let letters = Array(p.symbol)
                if !letters.isEmpty {
                    let letter = String(letters[i % letters.count])
                    layer.draw(Text(letter).font(.system(size: side, weight: .bold, design: .monospaced))
                        .foregroundColor(color), at: .zero)
                }
            case .image:
                if let picture = picture {
                    layer.draw(Image(uiImage: picture), in: box)
                }
            }
        }
    }
}

struct Burst: View {
    let start: Date

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                guard t < 3 else { return }
                for i in 0..<160 {
                    let turn = noise(i, 1) * 2 * Double.pi
                    let power = 80 + noise(i, 2) * 320
                    var layer = context
                    layer.opacity = max(0, 1 - t / 3)
                    let across: Double = Double(size.width) / 2 + cos(turn) * power * t
                    let fall: Double = 260 * t * t - 180 * t
                    let down: Double = Double(size.height) / 2 + sin(turn) * power * t + fall
                    layer.translateBy(x: across, y: down)
                    layer.rotate(by: .degrees(t * 500 * noise(i, 3)))
                    layer.fill(Path(CGRect(x: -5, y: -3, width: 10, height: 6)),
                               with: .color(Color(hue: noise(i, 4), saturation: 0.9, brightness: 1)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SpinnerLook: View {
    let paint: AnyShapeStyle
    let thickness: Double

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(paint, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(.degrees(t * 360))
                .padding(thickness / 2)
        }
    }
}

struct ScreenPicture: View {
    let frame: Frame
    var animated = true
    var body: some View {
        ZStack {
            Backdrop(screen: frame, animated: animated)
            ForEach(frame.elements.filter { !$0.hidden }) { element in
                ElementView(element: element)
                    .position(x: element.x, y: element.y)
            }
        }
        .frame(width: frame.size.width, height: frame.size.height)
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
                    Button("Centre on screen across") { apply { $0.x = model.frame.w / 2 } }
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
        let left = model.frame.w / 2 - total / 2
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
        let move = model.frame.h / 2 - (top + bottom) / 2
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
        let scale = 100 / max(frame.size.width, frame.size.height)
        return ScreenPicture(frame: frame, animated: false)
            .scaleEffect(scale)
            .frame(width: frame.size.width * scale, height: frame.size.height * scale)
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

    private var paint: AnyShapeStyle {
        makePaint([element.fill] + element.moreColors, angle: element.angle,
                  radial: element.radial, reach: max(element.w, element.h) * 0.7)
    }

    private var font: Font {
        let weights: [Font.Weight] = [.light, .regular, .semibold, .black]
        let index = min(max(element.weight, 0), 3)
        return .system(size: element.fontSize, weight: weights[index],
                       design: element.mono ? .monospaced : .rounded)
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

    private var ringLook: some View {
        let thickness = max(2, min(element.w, element.h) * 0.1)
        return ZStack {
            Circle().stroke(Color(white: 0.3), lineWidth: thickness)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(paint, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))%")
                .font(font)
                .foregroundColor(swatch(element.ink))
        }
        .padding(thickness / 2)
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
        case .clock:
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(font)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .foregroundColor(swatch(element.ink))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(shape.fill(paint))
            }
        case .spinner:
            SpinnerLook(paint: paint, thickness: max(2, min(element.w, element.h) * 0.1))
        case .ring:
            ringLook
        case .appIcon, .statusBar, .homeBar, .notification, .widget, .calculator, .notes:
            OSPartView(element: element, paint: paint, font: font)
        case .window, .shell, .panel:
            PCPartView(element: element, paint: paint, font: font, selectedTab: selectedTab)
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

// MARK: - OS parts

struct OSPartView: View {
    let element: Element
    let paint: AnyShapeStyle
    let font: Font

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: element.radius, style: .continuous)
    }

    private var ink: Color { swatch(element.ink) }

    private var lines: [String] { element.text.components(separatedBy: "\n") }

    var body: some View {
        switch element.kind {
        case .appIcon: appIcon
        case .statusBar: statusBar
        case .homeBar:
            Capsule()
                .fill(paint)
                .frame(height: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .notification: notification
        case .widget: widget
        case .calculator:
            CalculatorPad(element: element)
        case .notes:
            Text(element.text)
                .font(font)
                .foregroundColor(ink)
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(shape.fill(paint))
        default:
            EmptyView()
        }
    }

    private var appIcon: some View {
        let side = max(8, min(element.w, element.h - element.fontSize - 6))
        return VStack(spacing: 5) {
            ZStack {
                shape.fill(paint)
                if let data = element.image, let image = cachedImage(data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: element.imageFit ? .fit : .fill)
                        .frame(width: side, height: side)
                        .clipShape(shape)
                } else {
                    Text(String(element.text.prefix(2)))
                        .font(.system(size: side * 0.36, weight: .bold, design: .rounded))
                        .foregroundColor(ink)
                }
            }
            .frame(width: side, height: side)
            Text(element.text)
                .font(font)
                .foregroundColor(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var statusBar: some View {
        let level = min(1, max(0, element.value))
        return HStack(spacing: 8) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: .dateTime.hour().minute())
            }
            Spacer()
            Text(element.text).lineLimit(1)
            Text("\(Int((level * 100).rounded()))%")
            RoundedRectangle(cornerRadius: 3)
                .stroke(ink.opacity(0.6))
                .frame(width: 26, height: 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(level < 0.2 ? Color.red : ink)
                        .frame(width: 22 * level, height: 8)
                        .padding(.leading, 2)
                }
        }
        .font(font)
        .foregroundColor(ink)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(paint))
    }

    private var notification: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.green)
                .frame(width: 40, height: 40)
                .overlay(Text(String(element.text.prefix(1))).bold().foregroundColor(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(lines.first ?? "").bold()
                Text(lines.dropFirst().joined(separator: "\n"))
            }
            Spacer()
        }
        .font(font)
        .foregroundColor(ink)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(paint))
    }

    private var widget: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack {
                Text(context.date, format: .dateTime.weekday(.wide))
                    .font(.system(size: element.fontSize * 0.32, weight: .bold))
                    .foregroundColor(.red)
                Text(context.date, format: .dateTime.day())
                    .font(font)
                    .foregroundColor(ink)
                Text(context.date, format: .dateTime.month(.wide))
                    .font(.system(size: element.fontSize * 0.28))
                    .foregroundColor(ink)
            }
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(paint))
        }
    }
}

struct CalculatorPad: View {
    let element: Element
    @State private var display = "0"
    @State private var stored = 0.0
    @State private var operation = ""
    @State private var fresh = true

    private let rows = [["7", "8", "9", "/"], ["4", "5", "6", "x"],
                        ["1", "2", "3", "-"], ["C", "0", "=", "+"]]

    var body: some View {
        VStack(spacing: 8) {
            Text(display)
                .font(.system(size: element.fontSize * 1.6, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        .foregroundColor(swatch(element.ink))
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: element.radius, style: .continuous)
                .fill(swatch(element.fill))
        )
    }

    private func keyButton(_ key: String) -> some View {
        Button {
            press(key)
        } label: {
            Text(key)
                .font(.system(size: element.fontSize, weight: .semibold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Int(key) == nil ? Color.orange : Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func press(_ key: String) {
        if Int(key) != nil {
            if fresh { display = key; fresh = false }
            else if display.count < 12 { display += key }
        } else if key == "C" {
            display = "0"; stored = 0; operation = ""; fresh = true
        } else {
            let current = Double(display) ?? 0
            if !operation.isEmpty && !fresh {
                var result = current
                if operation == "+" { result = stored + current }
                if operation == "-" { result = stored - current }
                if operation == "x" { result = stored * current }
                if operation == "/" { result = current == 0 ? 0 : stored / current }
                display = String(format: "%.10g", result)
                stored = result
            } else {
                stored = current
            }
            operation = key == "=" ? "" : key
            fresh = true
        }
    }
}

// A notes box that remembers what was typed during prototypes.
struct NotesPad: View {
    let element: Element
    @AppStorage private var note: String

    init(element: Element) {
        self.element = element
        _note = AppStorage(wrappedValue: element.text, "note-" + element.link.uuidString)
    }

    var body: some View {
        TextEditor(text: $note)
            .scrollContentBackground(.hidden)
            .font(.system(size: element.fontSize))
            .foregroundColor(swatch(element.ink))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: element.radius, style: .continuous)
                    .fill(swatch(element.fill))
            )
            .frame(width: element.w, height: element.h)
            .opacity(element.opacity)
            .rotationEffect(.degrees(element.rotation))
    }
}

// MARK: - PC parts

let titleBarHeight: Double = 32

struct PCPartView: View {
    let element: Element
    let paint: AnyShapeStyle
    let font: Font
    var selectedTab = 0

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: element.radius, style: .continuous)
    }

    private var ink: Color { swatch(element.ink) }

    var body: some View {
        switch element.kind {
        case .window: window
        case .shell: shellPreview
        case .panel: panel
        default: EmptyView()
        }
    }

    private var window: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(element.text).font(font).lineLimit(1)
                Spacer()
                Text("-").bold().frame(width: 24, height: 22)
                    .background(Color.white.opacity(0.18))
                Text("x").bold().frame(width: 24, height: 22)
                    .background(Color.red.opacity(0.85))
            }
            .foregroundColor(ink)
            .padding(.horizontal, 8)
            .frame(height: titleBarHeight)
            .background(Color.white.opacity(0.14))
            Spacer(minLength: 0)
        }
        .background(Rectangle().fill(paint))
        .clipShape(shape)
        .overlay(shape.stroke(Color.white.opacity(0.25)))
    }

    private var shellPreview: some View {
        Text(element.text + "\n" + element.prompt + " _")
            .font(.system(size: element.fontSize, design: .monospaced))
            .foregroundColor(ink)
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(shape.fill(paint))
            .clipped()
    }

    private var panel: some View {
        let names = element.text.components(separatedBy: "\n")
        return HStack(spacing: 6) {
            ForEach(names.indices, id: \.self) { i in
                Text(names[i])
                    .lineLimit(1)
                    .frame(width: panelButtonWidth(element))
                    .frame(maxHeight: .infinity)
                    .background(Color.white.opacity(0.12))
            }
            Spacer(minLength: 0)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: .dateTime.hour().minute())
            }
        }
        .font(font)
        .foregroundColor(ink)
        .padding(4)
        .background(shape.fill(paint))
    }
}

func panelButtonWidth(_ element: Element) -> Double {
    let count = max(1, element.text.components(separatedBy: "\n").count)
    return max(20, min(110, (element.w - 90) / Double(count) - 6))
}

// A terminal that answers the commands written in the editor.
struct ShellView: View {
    let element: Element
    let open: (String) -> Void
    @State private var log: [String] = []
    @State private var input = ""

    // Each line is "command=answer" or "command>screen or layer name".
    private var custom: [(name: String, mark: Character, value: String)] {
        element.commands.components(separatedBy: "\n").compactMap {
            line -> (name: String, mark: Character, value: String)? in
            guard let cut = line.firstIndex(where: { $0 == "=" || $0 == ">" }) else { return nil }
            let name = line[..<cut].trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: cut)...])
                .trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : (name, line[cut], value)
        }
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text(([element.text] + log).joined(separator: "\n"))
                    HStack(spacing: 6) {
                        Text(element.prompt)
                        TextField("", text: $input)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit(run)
                    }
                    .id("input")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            }
            .onChange(of: log.count) { _ in reader.scrollTo("input", anchor: .bottom) }
        }
        .font(.system(size: element.fontSize, design: .monospaced))
        .foregroundColor(swatch(element.ink))
        .frame(width: element.w, height: element.h)
        .background(swatch(element.fill))
        .clipShape(RoundedRectangle(cornerRadius: element.radius, style: .continuous))
        .opacity(element.opacity)
    }

    private func run() {
        let typed = input.trimmingCharacters(in: .whitespaces)
        input = ""
        guard !typed.isEmpty else { return }
        log.append(element.prompt + " " + typed)
        if let match = custom.first(where: { $0.name.lowercased() == typed.lowercased() }) {
            if match.mark == ">" {
                open(match.value)
            } else {
                log.append(match.value.replacingOccurrences(of: "\\n", with: "\n"))
            }
        } else if typed == "clear" {
            log = []
        } else if typed == "help" {
            log.append((["help", "clear", "echo"] + custom.map { $0.name })
                .joined(separator: "  "))
        } else if typed.hasPrefix("echo ") {
            log.append(String(typed.dropFirst(5)))
        } else {
            log.append(typed + ": command not found")
        }
        if log.count > 200 { log.removeFirst(log.count - 200) }
    }
}

// MARK: - OS builder

enum OSKit {
    static func part(_ kind: Kind, _ text: String = "", x: Double = 195,
                     y: Double, fill: Int? = nil) -> Element {
        var e = makeElement(kind)
        if !text.isEmpty { e.text = text }
        e.x = x
        e.y = y
        if let fill = fill { e.fill = fill }
        return e
    }

    static func screen(_ name: String, colors: [Int] = [24, 25]) -> Frame {
        var frame = Frame(name: name)
        frame.fill = colors.first ?? 0
        frame.extra = Array(colors.dropFirst())
        return frame
    }

    static func boot(_ osName: String, next: UUID?) -> Frame {
        var frame = screen("Boot", colors: [0])
        var title = part(.text, osName, y: 340)
        title.w = 370; title.fontSize = 52; title.motion = .pop
        var spinner = part(.spinner, y: 500, fill: 4)
        spinner.w = 44; spinner.h = 44
        var wait = Interaction(action: next == nil ? .home : .goTo, screen: next)
        wait.trigger = .delay
        wait.wait = 2.5
        spinner.interactions = [wait]
        frame.elements = [title, spinner]
        return frame
    }

    static func lock() -> Frame {
        var frame = screen("Lock")
        var touch = part(.rect, y: 422, fill: noColor)
        touch.w = 390; touch.h = 844; touch.radius = 0; touch.name = "Swipe area"
        var swipe = Interaction(action: .home)
        swipe.trigger = .swipeUp
        swipe.transition = .slideUp
        touch.interactions = [swipe]
        var hint = part(.text, "Swipe up to unlock", y: 770)
        hint.w = 300; hint.fontSize = 17; hint.effect = .breathe
        hint.interactions = [swipe]
        let clock = part(.clock, y: 200)
        frame.elements = [touch, part(.statusBar, y: 22), clock, hint]
        return frame
    }

    // Each app is a name, a colour and the screen it opens.
    static func homeScreen(apps: [(String, Int, UUID?)]) -> Frame {
        var frame = screen("Home")
        frame.isHome = true
        var items = [part(.statusBar, y: 22)]
        for (index, app) in apps.enumerated() {
            let column = Double(index % 4)
            let row = Double(index / 4)
            var icon = part(.appIcon, app.0, x: 60 + column * 90, y: 120 + row * 110,
                            fill: app.1)
            if let target = app.2 {
                var open = Interaction(action: .goTo, screen: target)
                open.transition = .zoom
                icon.interactions = [open]
            }
            items.append(icon)
        }
        var dock = part(.rect, y: 740, fill: 30)
        dock.w = 360; dock.h = 100; dock.radius = 32; dock.name = "Dock"
        items.append(dock)
        items.append(part(.homeBar, y: 826))
        frame.elements = items
        return frame
    }

    static func appScreen(_ title: String, content: [Element]) -> Frame {
        var frame = screen(title, colors: [0])
        var heading = part(.text, title, y: 90)
        heading.w = 350; heading.fontSize = 34; heading.align = 0
        frame.elements = [part(.statusBar, y: 22), heading] + content
            + [part(.homeBar, y: 826)]
        return frame
    }

    static func settingsScreen() -> Frame {
        var about = part(.row, "About", y: 170)
        about.interactions = [Interaction(action: .popup, title: "About",
                                          message: "Version 3.33")]
        var update = part(.row, "Software Update", y: 232)
        update.interactions = [Interaction(action: .popup, title: "Up to date",
                                           message: "No updates found.")]
        let wifi = part(.toggle, "Wi-Fi", y: 294)
        let dark = part(.toggle, "Dark Mode", y: 356)
        let bright = part(.slider, y: 440)
        return appScreen("Settings", content: [about, update, wifi, dark, bright])
    }

    static func blankOS() -> Project {
        let home = homeScreen(apps: [])
        let lockFrame = lock()
        let start = boot("MyOS", next: lockFrame.id)
        return Project(name: "My OS", frames: [start, lockFrame, home])
    }

    static func trollOS() -> Project {
        let settings = settingsScreen()
        let notes = appScreen("Notes", content: [part(.notes, y: 380)])
        let calc = appScreen("Calculator", content: [part(.calculator, y: 480)])
        var log = part(.console, y: 400)
        log.h = 480
        let terminal = appScreen("Terminal", content: [log])
        var jailbroken = part(.text, "Not jailbroken", y: 200)
        jailbroken.w = 340
        let ring = part(.ring, y: 390)
        var go = part(.button, "Jailbreak", y: 600)
        go.w = 260
        var respring = Interaction(action: .respring)
        respring.trigger = .tap
        var change = Interaction(action: .setText, layer: jailbroken.id)
        change.newText = "Jailbreaking..."
        go.interactions = [change, Interaction(action: .load)]
        var spring = part(.button, "Respring", y: 680, fill: 2)
        spring.w = 260
        spring.interactions = [respring]
        let jail = appScreen("fiji333", content: [jailbroken, ring, go, spring])
        let home = homeScreen(apps: [
            ("Settings", 3, settings.id), ("Notes", 7, notes.id),
            ("Calc", 6, calc.id), ("Terminal", 1, terminal.id), ("fiji333", 9, jail.id)
        ])
        let lockFrame = lock()
        let start = boot("TrollOS", next: lockFrame.id)
        return Project(name: "TrollOS",
                       frames: [start, lockFrame, home, settings, notes, calc, terminal, jail])
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
        let new = fitted(makeElement(kind), on: frame)
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
        new = fitted(new, on: frame)
        new.image = result.data
        new.w = min(280, frame.w)
        new.h = min(frame.h, new.w * Double(result.size.height / result.size.width))
        frame.elements.append(new)
        selected = new.id
    }

    func delete() {
        guard let id = selected else { return }
        checkpoint()
        frame.elements.removeAll { $0.id == id }
        for i in frame.elements.indices where frame.elements[i].parent == id {
            frame.elements[i].parent = nil
        }
        selected = nil
    }

    func reorder(toFront: Bool) {
        guard let item = element else { return }
        checkpoint()
        frame.elements.removeAll { $0.id == item.id }
        if toFront { frame.elements.append(item) }
        else { frame.elements.insert(item, at: 0) }
    }

    func append(_ new: Frame) {
        checkpoint()
        var screen = new
        // Keep only one home screen.
        if project.frames.contains(where: { $0.isHome == true }) { screen.isHome = nil }
        project.frames.append(screen)
        frameIndex = project.frames.count - 1
        selected = nil
    }

    // Copies every screen of another design into this one and keeps its links working.
    func merge(_ other: Project) {
        checkpoint()
        var screens: [UUID: UUID] = [:]
        var layers: [UUID: UUID] = [:]
        var incoming = other.frames
        for i in incoming.indices {
            let fresh = UUID()
            screens[incoming[i].id] = fresh
            incoming[i].id = fresh
            for j in incoming[i].elements.indices {
                let layer = UUID()
                layers[incoming[i].elements[j].id] = layer
                incoming[i].elements[j].id = layer
                incoming[i].elements[j].link = UUID()
            }
        }
        let hasHome = project.frames.contains { $0.isHome == true }
        let names = Set(project.frames.map { $0.name })
        for i in incoming.indices {
            if hasHome { incoming[i].isHome = nil }
            if names.contains(incoming[i].name) {
                incoming[i].name += " (" + other.name + ")"
            }
            for j in incoming[i].elements.indices {
                for k in incoming[i].elements[j].interactions.indices {
                    incoming[i].elements[j].interactions[k]
                        .relink(layers: layers, screens: screens)
                }
                incoming[i].elements[j].tabTargets = incoming[i].elements[j].tabTargets.map {
                    target in target.map { screens[$0] ?? layers[$0] ?? $0 }
                }
                if let old = incoming[i].elements[j].parent {
                    incoming[i].elements[j].parent = layers[old]
                }
            }
        }
        let first = project.frames.count
        project.frames += incoming
        frameIndex = min(first, project.frames.count - 1)
        selected = nil
    }

    func addSized(_ width: Double, _ height: Double) {
        addFrame(copying: false)
        frame.width = width
        frame.height = height
    }

    // Changes the screen size and keeps layers in the same relative places.
    func resize(_ width: Double, _ height: Double) {
        let sx = width / frame.w
        let sy = height / frame.h
        var screen = frame
        for i in screen.elements.indices {
            let old = screen.elements[i]
            let fill = old.w >= screen.w && old.h >= screen.h
            screen.elements[i].x = old.x * sx
            screen.elements[i].y = old.y * sy
            screen.elements[i].w = fill ? width : min(old.w, width)
            screen.elements[i].h = fill ? height : min(old.h, height)
        }
        screen.width = width
        screen.height = height
        frame = screen
    }

    func moveFrame(to target: Int) {
        guard project.frames.indices.contains(target), target != frameIndex else { return }
        checkpoint()
        let moving = project.frames.remove(at: frameIndex)
        project.frames.insert(moving, at: target)
        frameIndex = target
    }

    func setHome(_ on: Bool) {
        let current = frame.id
        for i in project.frames.indices {
            if project.frames[i].id == current { project.frames[i].isHome = on ? true : nil }
            else if on { project.frames[i].isHome = nil }
        }
    }

    func addFrame(copying: Bool) {
        checkpoint()
        var new = copying ? frame : Frame(name: "")
        new.width = frame.width
        new.height = frame.height
        new.id = UUID()
        new.isHome = nil
        new.name = "Screen \(project.frames.count + 1)"
        if copying {
            var ids: [UUID: UUID] = [:]
            for i in new.elements.indices {
                let fresh = UUID()
                ids[new.elements[i].id] = fresh
                new.elements[i].id = fresh
            }
            for i in new.elements.indices {
                if let old = new.elements[i].parent { new.elements[i].parent = ids[old] }
                new.elements[i].tabTargets = new.elements[i].tabTargets.map {
                    target in target.map { ids[$0] ?? $0 }
                }
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
    @AppStorage("previewFX") private var previewFX = true
    @AppStorage("accent") private var accent = 10
    @AppStorage("editorBack") private var editorBack = 30
    @AppStorage("nudgeStep") private var nudgeStep = 1.0
    @State private var pickingPhoto = false
    @State private var photo: PhotosPickerItem?

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
            FilePicker.save(data, name: Vault.safeName(model.project.name) + ".json")
        }
    }

    private func exportScreen(share: Bool) {
        let renderer = ImageRenderer(content: ScreenPicture(frame: model.frame))
        renderer.scale = 3
        guard let data = renderer.uiImage?.pngData() else { return }
        let name = Vault.safeName(model.frame.name) + ".png"
        if share { FilePicker.share(data, name: name) }
        else { FilePicker.save(data, name: name) }
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
                Button("Save screen as PNG") { exportScreen(share: false) }
                Button("Share screen as PNG") { exportScreen(share: true) }
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
                addScreenMenu
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

    private var addScreenMenu: some View {
        Menu("+ Screen") {
            Button("Blank screen") { model.addFrame(copying: false) }
            Button("Blank phone screen") { model.addSized(390, 844) }
            Button("Blank PC screen") { model.addSized(960, 540) }
            Menu("OS screens") {
                Button("Boot screen") { model.append(OSKit.boot(model.project.name, next: nil)) }
                Button("Lock screen") { model.append(OSKit.lock()) }
                Button("Home screen") { model.append(OSKit.homeScreen(apps: [])) }
                Button("Settings app") { model.append(OSKit.settingsScreen()) }
                Button("Empty app") { model.append(OSKit.appScreen("App", content: [])) }
                Button("Notes app") {
                    model.append(OSKit.appScreen("Notes",
                                                 content: [OSKit.part(.notes, y: 380)]))
                }
                Button("Calculator app") {
                    model.append(OSKit.appScreen("Calculator",
                                                 content: [OSKit.part(.calculator, y: 480)]))
                }
            }
            Menu("Merge a design") {
                ForEach(store.projects.filter { $0.id != model.project.id }) { other in
                    Button(other.name) { model.merge(other) }
                }
                Button("From a file") {
                    FilePicker.open([.json, .text, .data]) { data in
                        if let other = try? JSONDecoder().decode(Project.self, from: data),
                           !other.frames.isEmpty {
                            model.merge(other)
                        }
                    }
                }
            }
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
                ForEach(Kind.allCases.filter {
                    $0 != .image && !Kind.osParts.contains($0) && !Kind.pcParts.contains($0)
                }) { kind in
                    Button(kind.rawValue) { model.add(kind) }
                }
                Menu("PC parts") {
                    ForEach(Kind.pcParts) { kind in
                        Button(kind.rawValue) { model.add(kind) }
                    }
                    Button("Desktop icon") { model.add(.appIcon) }
                }
                Menu("OS parts") {
                    ForEach(Kind.osParts) { kind in
                        Button(kind.rawValue) { model.add(kind) }
                    }
                }
                Button("Image from Photos") { pickingPhoto = true }
                Button("Image from Files") {
                    FilePicker.open([.image]) { data in model.addImage(data) }
                }
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
                Toggle("Preview effects", isOn: $previewFX)
            }
        }
        .padding()
        .background(Color(white: 0.17))
    }
}

struct CanvasView: View {
    @EnvironmentObject var store: Store
    @ObservedObject var model: EditorModel
    let snap: Bool
    let grid: Bool
    @AppStorage("outline") private var outline = 23
    @AppStorage("previewFX") private var previewFX = true
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
            let fit = max(0.1, min((geo.size.width - 24) / model.frame.size.width,
                                   (geo.size.height - 16) / model.frame.size.height))
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
            Backdrop(screen: model.frame)
                .onTapGesture { model.selected = nil }
            if showEffects { particles(front: false) }
            ForEach(model.frame.elements) { element in
                item(element)
            }
            if showEffects { particles(front: true) }
            if grid { gridLines }
        }
        .frame(width: model.frame.size.width, height: model.frame.size.height)
        .coordinateSpace(name: "canvas")
        .clipped()
        .border(Color.gray.opacity(0.5))
    }

    @ViewBuilder private func particles(front: Bool) -> some View {
        let list = (model.frame.particles ?? []).filter { $0.front == front }
        if !list.isEmpty {
            ParticleField(systems: list)
        }
    }

    // Editor animations pause while a prototype is playing.
    private var showEffects: Bool {
        previewFX && store.playing == nil
    }

    private var gridLines: some View {
        Path { path in
            let space = CGFloat(max(5, gridSize))
            for x in stride(from: space, to: model.frame.size.width, by: space) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: model.frame.size.height))
            }
            for y in stride(from: space, to: model.frame.size.height, by: space) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: model.frame.size.width, y: y))
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
            .modifier(Effects(element: element, active: showEffects))
            .opacity(element.hidden ? 0.25 : 1)
            .contentShape(Rectangle())
            // Stops interactive parts catching touches while editing.
            .overlay { Color.clear.contentShape(Rectangle()) }
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
                    let middle = model.frame.w / 2
                    if abs(x - middle) < 10 { x = middle }
                    let centre = model.frame.h / 2
                    if abs(y - centre) < 10 { y = centre }
                }
                let now = model.frame.elements.first { $0.id == element.id }
                let dx = x - (now?.x ?? x)
                let dy = y - (now?.y ?? y)
                model.change(element.id) { $0.x = x; $0.y = y }
                // Attached layers travel with their window.
                for child in model.frame.elements where child.parent == element.id {
                    model.change(child.id) { $0.x += dx; $0.y += dy }
                }
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
            Group {
            if e.wrappedValue.kind == .image || e.wrappedValue.kind == .appIcon {
                ImageSection(element: e)
            }
            if e.wrappedValue.kind == .statusBar {
                Section("Status bar") {
                    SliderRow(title: "Battery level", value: e.value, range: 0...1, step: 0.05)
                }
            }
            }
            if e.wrappedValue.kind == .slider {
                Section("Slider") {
                    SliderRow(title: "Start value", value: e.value, range: 0...1, step: 0.05)
                    Toggle("Show percentage", isOn: e.showValue)
                    Text("Add the trigger On slider reaches end for slide to jailbreak.")
                        .font(.caption)
                }
            }
            Group {
            if e.wrappedValue.kind == .tabs || e.wrappedValue.kind == .panel {
                TabsSection(model: model, element: e)
            }
            if e.wrappedValue.kind == .shell {
                Section("Terminal commands") {
                    TextField("Prompt", text: e.prompt)
                        .textInputAutocapitalization(.never)
                    TextField("neofetch=MyOS 1.0", text: e.commands, axis: .vertical)
                        .lineLimit(3...12)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("One per line. name=answer prints text. name>Screen or layer name opens it.")
                        .font(.caption)
                }
            }
            }
            if e.wrappedValue.kind == .console {
                consoleSection(e)
            }
            Section("Effect") {
                Picker("Effect", selection: e.effect) {
                    ForEach(EffectKind.allCases) { Text($0.rawValue).tag($0) }
                }
                if e.wrappedValue.effect != .none {
                    SliderRow(title: "Effect speed", value: e.effectSpeed, range: 0.1...4,
                              step: 0.1, unlocked: 0.01...30)
                }
            }
            if hasText(e.wrappedValue.kind) {
                textSection(e)
            }
            layoutSection(e)
            styleSection(e)
            Section("Layer") {
                TextField("Layer name", text: e.name)
                if e.wrappedValue.kind != .window {
                    Picker("Attach to window", selection: e.parent) {
                        Text("None").tag(UUID?.none)
                        ForEach(model.frame.elements.filter { $0.kind == .window }) { window in
                            Text(window.label + " " + window.text).tag(Optional(window.id))
                        }
                    }
                }
                Toggle("Monospaced text", isOn: e.mono)
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
            || kind == .slider || kind == .tabs || kind == .clock || kind == .ring || kind == .appIcon || kind == .statusBar
            || kind == .notification || kind == .widget || kind == .calculator || kind == .notes
            || Kind.pcParts.contains(kind)
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
            SliderRow(title: "X", value: e.x, range: 0...model.frame.w,
                      unlocked: -3000...3000)
            SliderRow(title: "Y", value: e.y, range: 0...model.frame.h,
                      unlocked: -3000...4000)
            SliderRow(title: "Width", value: e.w, range: 4...model.frame.w,
                      unlocked: 1...5000)
            SliderRow(title: "Height", value: e.h, range: 4...model.frame.h,
                      unlocked: 1...5000)
            SliderRow(title: "Rotation", value: e.rotation, range: -180...180,
                      unlocked: -3600...3600)
            HStack {
                Button("Left") { e.wrappedValue.x = e.wrappedValue.w / 2 }
                Button("Centre") { e.wrappedValue.x = model.frame.w / 2 }
                Button("Right") { e.wrappedValue.x = model.frame.w - e.wrappedValue.w / 2 }
            }
            .buttonStyle(.bordered)
            HStack {
                Button("Top") { e.wrappedValue.y = e.wrappedValue.h / 2 }
                Button("Middle") { e.wrappedValue.y = model.frame.h / 2 }
                Button("Bottom") { e.wrappedValue.y = model.frame.h - e.wrappedValue.h / 2 }
            }
            .buttonStyle(.bordered)
            Button("Fill screen") {
                var value = e.wrappedValue
                value.x = model.frame.w / 2; value.y = model.frame.h / 2
                value.w = model.frame.w; value.h = model.frame.h; value.radius = 0
                e.wrappedValue = value
            }
        }
    }

    private func styleSection(_ e: Binding<Element>) -> some View {
        Section("Style") {
            GradientEditor(
                fill: e.fill,
                extra: Binding(
                    get: { e.wrappedValue.moreColors },
                    set: { colors in
                        var value = e.wrappedValue
                        value.extra = colors
                        value.fill2 = nil
                        e.wrappedValue = value
                    }
                ),
                angle: e.angle,
                radial: e.radial
            )
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
            if element.kind == .appIcon && element.image != nil {
                Button("Remove picture", role: .destructive) { element.image = nil }
            }
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
                    if element.kind == .panel {
                        ForEach(model.frame.elements.filter { $0.id != element.id }) { layer in
                            Text("Show/hide " + layer.label + " " + String(layer.text.prefix(10)))
                                .tag(Optional(layer.id))
                        }
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
            Section("Type") {
                Picker("Popup type", selection: $item.style) {
                    ForEach(PopupStyle.allCases) { Text($0.rawValue).tag($0) }
                }
                if item.style != .custom {
                    Text("Uses the real system popup, so iOS decides the colours and layout.")
                        .font(.caption)
                }
            }
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
                    if item.style == .custom {
                        Swatches(title: "Button colour", selection: $button.fill)
                        Swatches(title: "Button text colour", selection: $button.ink)
                    } else {
                        Picker("Button style", selection: Binding(
                            get: { button.role ?? .normal },
                            set: { button.role = $0 }
                        )) {
                            ForEach(PopupRole.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }
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
                    cancel.role = .cancel
                    item.buttons = [cancel, PopupButton()]
                }
                if item.style == .custom {
                    Toggle("Stack buttons vertically", isOn: $item.popupStack)
                    if item.buttons.isEmpty {
                        Text("With no buttons, tapping outside closes the popup.")
                            .font(.caption)
                    }
                }
            }
            Section("Timing") {
                SliderRow(title: "Close by itself after (s, 0 is off)", value: $item.autoClose,
                          range: 0...20, unlocked: 0...600)
            }
            if item.style == .custom {
                lookSection
            }
        }
        .navigationTitle("Popup")
    }

    private var lookSection: some View {
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
            }
    }
}

struct ParticlePreview: View {
    let systems: [Particles]
    var body: some View {
        ParticleField(systems: systems)
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ParticlesPage: View {
    @Binding var list: [Particles]

    var body: some View {
        Form {
            ParticlePreview(systems: list)
            ForEach($list) { $system in
                Section {
                    NavigationLink("Edit " + system.name) {
                        ParticleEditor(system: $system)
                    }
                    Button("Duplicate") {
                        var copy = system
                        copy.id = UUID()
                        list.append(copy)
                    }
                    Button("Remove", role: .destructive) {
                        let id = system.id
                        list.removeAll { $0.id == id }
                    }
                }
            }
            Menu("+ Add particles") {
                ForEach(Particles.presetNames, id: \.self) { name in
                    Button(name == "Custom" ? "Create your own" : name) {
                        list.append(Particles.preset(name))
                    }
                }
            }
        }
        .navigationTitle("Particles")
    }
}

struct ParticleEditor: View {
    @Binding var system: Particles
    @State private var photo: PhotosPickerItem?

    var body: some View {
        Form {
            ParticlePreview(systems: [system])
            lookSection
            colorSection
            motionSection
        }
        .navigationTitle(system.name)
        .onChange(of: photo) { item in
            guard let item = item else { return }
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self),
                   let result = prepareImage(data),
                   let image = UIImage(data: result.data) {
                    // Particle pictures are kept small.
                    let ratio = min(1, 128 / max(image.size.width, image.size.height))
                    let size = CGSize(width: image.size.width * ratio,
                                      height: image.size.height * ratio)
                    system.image = image.preparingThumbnail(of: size)?.pngData() ?? result.data
                }
                photo = nil
            }
        }
    }

    private var lookSection: some View {
        Section("Look") {
            TextField("Name", text: $system.name)
            Picker("Shape", selection: $system.shape) {
                ForEach(ParticleShape.allCases) { Text($0.rawValue).tag($0) }
            }
            if system.shape == .text {
                TextField("Characters or emoji", text: $system.symbol)
            }
            if system.shape == .image {
                PhotosPicker("Choose picture", selection: $photo, matching: .images)
            }
            SliderRow(title: "Smallest size", value: $system.minSize, range: 1...60,
                      unlocked: 1...400)
            SliderRow(title: "Largest size", value: $system.maxSize, range: 1...60,
                      unlocked: 1...400)
            SliderRow(title: "Opacity", value: $system.opacity, range: 0.05...1, step: 0.05)
            Toggle("Twinkle", isOn: $system.twinkle)
            Toggle("In front of layers", isOn: $system.front)
        }
    }

    private var colorSection: some View {
        Section("Colours (text and shapes)") {
            Toggle("Rainbow", isOn: $system.rainbow)
            if !system.rainbow {
                ForEach(system.colors.indices, id: \.self) { i in
                    Swatches(title: "Colour \(i + 1)", selection: color(i))
                }
                Button("+ Add colour") { system.colors.append(10) }
                Button("Remove last colour", role: .destructive) {
                    if system.colors.count > 1 { system.colors.removeLast() }
                }
                .disabled(system.colors.count < 2)
            }
        }
    }

    private var motionSection: some View {
        Section("Movement") {
            SliderRow(title: "Amount", value: $system.count, range: 1...200,
                      unlocked: 1...1500)
            SliderRow(title: "Speed", value: $system.speed, range: 0...700, step: 10,
                      unlocked: 0...4000)
            SliderRow(title: "Direction (0 down, 180 up)", value: $system.direction,
                      range: 0...360, step: 15)
            SliderRow(title: "Wobble", value: $system.wobble, range: 0...80,
                      unlocked: 0...500)
            SliderRow(title: "Spin", value: $system.spin, range: 0...360, step: 15,
                      unlocked: 0...3000)
        }
    }

    private func color(_ index: Int) -> Binding<Int> {
        Binding(
            get: { system.colors.indices.contains(index) ? system.colors[index] : 4 },
            set: { if system.colors.indices.contains(index) { system.colors[index] = $0 } }
        )
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
        Group {
        if item.action.needsScreen {
            Picker("Destination", selection: $item.screen) {
                Text("None").tag(UUID?.none)
                ForEach(model.project.frames) { frame in
                    Text(frame.name).tag(Optional(frame.id))
                }
            }
        }
        if item.action == .home {
            Text("Mark a screen as home in the Screen panel.")
                .font(.caption)
        }
        if item.action.needsScreen || item.action == .home {
            Picker("Transition", selection: $item.transition) {
                ForEach(ScreenTransition.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Easing", selection: $item.easing) {
                ForEach(Easing.allCases) { Text($0.rawValue).tag($0) }
            }
            SliderRow(title: "Duration (s)", value: $item.duration, range: 0.1...2, step: 0.05,
                      unlocked: 0.05...60)
        }
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
        if item.action == .sound {
            Picker("Sound", selection: $item.sound) {
                ForEach(SoundKind.allCases) { Text($0.title).tag($0) }
            }
            Button("Test sound") { AudioServicesPlaySystemSound(SystemSoundID(item.sound.rawValue)) }
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
                Section("Background") {
                    GradientEditor(
                        fill: Binding(
                            get: { model.frame.fill },
                            set: { model.frame.fill = $0 }
                        ),
                        extra: Binding(
                            get: { model.frame.extra ?? [] },
                            set: { model.frame.extra = $0 }
                        ),
                        angle: Binding(
                            get: { model.frame.angle ?? 0 },
                            set: { model.frame.angle = $0 }
                        ),
                        radial: Binding(
                            get: { model.frame.radial ?? false },
                            set: { model.frame.radial = $0 }
                        )
                    )
                }
                Section("Effects") {
                    NavigationLink("Particles: \(model.frame.particles?.count ?? 0)") {
                        ParticlesPage(list: Binding(
                            get: { model.frame.particles ?? [] },
                            set: { model.frame.particles = $0 }
                        ))
                    }
                    Toggle("Rainbow background", isOn: Binding(
                        get: { model.frame.rainbow ?? false },
                        set: { model.frame.rainbow = $0 }
                    ))
                    if model.frame.rainbow ?? false {
                        SliderRow(title: "Rainbow speed", value: Binding(
                            get: { model.frame.rainbowSpeed ?? 1 },
                            set: { model.frame.rainbowSpeed = $0 }
                        ), range: 0.1...5, step: 0.1, unlocked: 0.01...40)
                    }
                }
                Section("Screen size: \(Int(model.frame.w)) x \(Int(model.frame.h))") {
                    Menu("Choose a size") {
                        Button("Phone") { model.resize(390, 844) }
                        Button("Tablet") { model.resize(820, 1180) }
                        Button("PC wide 16:9") { model.resize(960, 540) }
                        Button("PC classic 4:3") { model.resize(800, 600) }
                        Button("PC ultrawide") { model.resize(1260, 540) }
                    }
                    SliderRow(title: "Width", value: Binding(
                        get: { model.frame.w },
                        set: { model.frame.width = $0 }
                    ), range: 300...1400, step: 10, unlocked: 100...4000)
                    SliderRow(title: "Height", value: Binding(
                        get: { model.frame.h },
                        set: { model.frame.height = $0 }
                    ), range: 300...1400, step: 10, unlocked: 100...4000)
                }
                Section("Order and home") {
                    Toggle("This is the home screen", isOn: Binding(
                        get: { model.frame.isHome == true },
                        set: { model.setHome($0) }
                    ))
                    Button("Move earlier") { model.moveFrame(to: model.frameIndex - 1) }
                        .disabled(model.frameIndex == 0)
                    Button("Move later") { model.moveFrame(to: model.frameIndex + 1) }
                        .disabled(model.frameIndex >= model.project.frames.count - 1)
                    Button("Start the prototype here") { model.moveFrame(to: 0) }
                        .disabled(model.frameIndex == 0)
                }
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

// MARK: - Experimental Labs

enum ScreenFilter: String, CaseIterable, Identifiable {
    case none = "None"
    case crt = "Old CRT"
    case mono = "Black and white"
    case invert = "Inverted"
    case vapor = "Vaporwave"
    case night = "Night vision"
    var id: String { rawValue }
}

struct LabsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("labFilter") private var filter = ScreenFilter.none.rawValue
    @AppStorage("labTilt") private var tilt = false
    @AppStorage("labTiltAmount") private var tiltAmount = 18.0
    @AppStorage("labRipple") private var ripple = false
    @State private var name = "fiji333"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Jailbreak name", text: $name)
                    Button("Generate a random jailbreak") {
                        let project = Templates.random(name: name)
                        store.add(project)
                        store.editing = project.id
                        dismiss()
                    }
                } header: {
                    Text("Magic generator")
                } footer: {
                    Text("Builds a new design with random colours, particles and effects.")
                }
                Section("Prototype screen filter") {
                    Picker("Filter", selection: $filter) {
                        ForEach(ScreenFilter.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                }
                Section("Prototype interaction") {
                    Toggle("3D tilt (move your phone)", isOn: $tilt)
                    if tilt {
                        SliderRow(title: "Tilt strength", value: $tiltAmount, range: 4...50,
                                  unlocked: 0...200)
                    }
                    Toggle("Touch ripples", isOn: $ripple)
                }
                Text("Labs features are experimental and may change.")
                    .font(.caption)
            }
            .navigationTitle("Labs")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

struct BackupsView: View {
    @EnvironmentObject var store: Store
    @State private var files: [URL] = []
    @State private var message = ""
    @State private var showMessage = false

    var body: some View {
        List {
            if files.isEmpty { Text("No backups yet") }
            ForEach(files, id: \.self) { file in
                Button(file.deletingPathExtension().lastPathComponent) { restore(file) }
            }
        }
        .navigationTitle("Backups")
        .onAppear { files = Vault.files(in: Vault.backups) }
        .alert(message, isPresented: $showMessage) {
            Button("OK", role: .cancel) {}
        }
    }

    // Restored designs are added as copies, so nothing is overwritten.
    private func restore(_ file: URL) {
        let count = readFile(file).map { store.importData($0) } ?? 0
        message = count > 0 ? "Added \(count) design(s)" : "That backup could not be read"
        showMessage = true
    }
}

final class TiltMonitor: ObservableObject {
    @Published var x = 0.0
    @Published var y = 0.0
    private let manager = CMMotionManager()
    private var origin: (Double, Double)?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        origin = nil
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            let base = self.origin ?? (roll, pitch)
            self.origin = base
            self.x = max(-1, min(1, roll - base.0))
            self.y = max(-1, min(1, pitch - base.1))
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        x = 0
        y = 0
    }
}

struct Parallax: ViewModifier {
    @ObservedObject var monitor: TiltMonitor
    let depth: Double

    func body(content: Content) -> some View {
        content.offset(x: monitor.x * depth, y: monitor.y * depth)
    }
}

struct FilterLook: ViewModifier {
    let filter: ScreenFilter

    func body(content: Content) -> some View {
        content
            .grayscale(filter == .mono || filter == .night ? 1 : 0)
            .colorMultiply(filter == .night ? .green : .white)
            .hueRotation(.degrees(filter == .vapor ? 60 : 0))
            .saturation(filter == .vapor ? 1.8 : 1)
            .overlay(overlay.allowsHitTesting(false))
    }

    @ViewBuilder private var overlay: some View {
        if filter == .invert {
            Color.white.blendMode(.difference)
        } else if filter == .crt || filter == .night {
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 4) {
                    context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1.5)),
                                 with: .color(Color.black.opacity(0.35)))
                }
            }
        }
    }
}

struct Ripple: Identifiable {
    let id = UUID()
    let point: CGPoint
}

struct RippleView: View {
    @State private var grown = false

    var body: some View {
        Circle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: 70, height: 70)
            .scaleEffect(grown ? 1.4 : 0.1)
            .opacity(grown ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.55)) { grown = true }
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
    @State private var shakes: CGFloat = 0
    @State private var flashAmount = 0.0
    @State private var particlesOff = false
    @State private var burstStart: Date?
    @State private var moved: [UUID: CGSize] = [:]
    @State private var dragStart: CGSize?
    @State private var order: [UUID: Double] = [:]
    @State private var topOrder = 0.0
    @State private var tilt = TiltMonitor()
    @State private var ripples: [Ripple] = []
    @AppStorage("labFilter") private var filterName = ScreenFilter.none.rawValue
    @AppStorage("labTilt") private var tiltOn = false
    @AppStorage("labTiltAmount") private var tiltAmount = 18.0
    @AppStorage("labRipple") private var rippleOn = false
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
            let size = frame.size
            // Wide screens turn sideways while the phone is upright.
            let turned = size.width > size.height && geo.size.height > geo.size.width
            let roomW = turned ? geo.size.height : geo.size.width
            let roomH = turned ? geo.size.width : geo.size.height
            let scale = min(roomW / size.width, roomH / size.height)
            ZStack {
                Backdrop(screen: frame)
                ZStack {
                    screenLayer(frame)
                        .id(layer)
                        .transition(transition.effect)
                }
                .frame(width: size.width, height: size.height)
                .modifier(ShakeEffect(amount: shakes))
                .clipped()
                .scaleEffect(scale)
                .rotationEffect(.degrees(turned ? 90 : 0))
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .blur(radius: receding ? 24 : 0)
                .scaleEffect(receding ? 0.88 : 1)
                .modifier(FilterLook(filter: ScreenFilter(rawValue: filterName) ?? .none))
                ForEach(ripples) { ripple in
                    RippleView()
                        .position(ripple.point)
                        .allowsHitTesting(false)
                }
                if let start = burstStart {
                    Burst(start: start).id(start)
                }
                Color.white
                    .opacity(flashAmount)
                    .allowsHitTesting(false)
                if hint && showHint { hintView }
                if let item = popup, item.style == .custom {
                    PopupOverlay(item: item, choose: choose)
                        .id(popupVisit)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
                RespringOverlay(stage: stage, unlock: unlock)
                    .allowsHitTesting(stage != .idle)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(LongPressGesture(minimumDuration: max(0.8, exitHold)).onEnded { _ in menu = true })
            .simultaneousGesture(SpatialTapGesture().onEnded { tap in addRipple(tap.location) },
                                 including: rippleOn ? .all : .subviews)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            schedule()
            if tiltOn { tilt.start() }
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            hint = false
        }
        .onDisappear {
            cancelAll()
            respringTask?.cancel()
            tilt.stop()
        }
        .background(alertHost)
        .overlay(sheetHost.allowsHitTesting(false))
        .task(id: popupVisit) { await autoCloseSystemPopup() }
        .task(id: burstStart) {
            guard burstStart != nil else { return }
            try? await Task.sleep(nanoseconds: 3_100_000_000)
            if !Task.isCancelled { burstStart = nil }
        }
        .tint(Color(uiColor: .systemBlue))
        .confirmationDialog("Prototype", isPresented: $menu) {
            Button("Restart") {
                respringTask?.cancel()
                stage = .idle
                restart()
            }
            Button("Exit prototype", role: .destructive) { store.playing = nil }
        }
    }

    private func showing(_ style: PopupStyle) -> Binding<Bool> {
        Binding(
            get: { popup?.style == style },
            set: { open in
                if !open && popup?.style == style { popup = nil }
            }
        )
    }

    private var alertHost: some View {
        Color.clear
            .alert(popup?.title ?? "", isPresented: showing(.alert), presenting: popup) { item in
                systemButtons(item)
            } message: { item in
                Text(item.message)
            }
    }

    private var sheetHost: some View {
        Color.clear
            .confirmationDialog(popup?.title ?? "", isPresented: showing(.sheet),
                                titleVisibility: .visible, presenting: popup) { item in
                systemButtons(item)
            } message: { item in
                Text(item.message)
            }
    }

    private func systemButtons(_ item: Interaction) -> some View {
        // iOS allows only one cancel button.
        let cancel = item.buttons.first { $0.role == .cancel }?.id
        return ForEach(item.buttons) { button in
            Button(button.title, role: role(button, cancel: cancel)) {
                choose(button)
            }
        }
    }

    private func role(_ button: PopupButton, cancel: UUID?) -> ButtonRole? {
        if button.id == cancel { return .cancel }
        return button.role == .destructive ? .destructive : nil
    }

    private func autoCloseSystemPopup() async {
        guard let item = popup, item.style != .custom, item.autoClose > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(item.autoClose * 1_000_000_000))
        if !Task.isCancelled { popup = nil }
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
            Backdrop(screen: screen)
            particleLayer(screen, front: false)
            ForEach(Array(screen.elements.enumerated()), id: \.element.link) { index, element in
                playable(element)
                    .offset(moved[element.parent ?? element.id] ?? .zero)
                    .modifier(Parallax(monitor: tilt, depth: depth(index, screen.elements.count)))
                    .zIndex(order[element.parent ?? element.id] ?? 0)
            }
            particleLayer(screen, front: true)
                .zIndex(1_000_000)
        }
        .frame(width: screen.size.width, height: screen.size.height)
        .coordinateSpace(name: "play")
    }

    // Layers nearer the front move further.
    private func depth(_ index: Int, _ count: Int) -> Double {
        guard tiltOn, count > 0 else { return 0 }
        return tiltAmount * Double(index + 1) / Double(count)
    }

    private func addRipple(_ point: CGPoint) {
        let ripple = Ripple(point: point)
        ripples.append(ripple)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }

    @ViewBuilder private func particleLayer(_ screen: Frame, front: Bool) -> some View {
        let list = (screen.particles ?? []).filter { $0.front == front }
        if !list.isEmpty && !particlesOff {
            ParticleField(systems: list)
        }
    }

    private func flash() {
        flashAmount = 0.9
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.5)) { flashAmount = 0 }
        }
    }

    private func isVisible(_ element: Element) -> Bool {
        let own = visibility[element.id] ?? !element.hidden
        guard let id = element.parent,
              let window = frame.elements.first(where: { $0.id == id }) else { return own }
        return own && (visibility[window.id] ?? !window.hidden)
    }

    // Brings a window and its attached layers to the front.
    private func raise(_ id: UUID) {
        guard order[id] != topOrder || topOrder == 0 else { return }
        topOrder += 1
        order[id] = topOrder
    }

    private func windowTouch(_ element: Element) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .named("play"))
                            .onChanged { drag in
                                let base = dragStart ?? moved[element.id] ?? .zero
                                dragStart = base
                                raise(element.id)
                                moved[element.id] = CGSize(
                                    width: base.width + drag.translation.width,
                                    height: base.height + drag.translation.height)
                            }
                            .onEnded { _ in dragStart = nil }
                    )
                ForEach(0..<2, id: \.self) { _ in
                    Color.clear
                        .frame(width: 24)
                        .contentShape(Rectangle())
                        .onTapGesture { setLayer(element.id, visible: false) }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: titleBarHeight)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    raise(element.id)
                    fire(element, .tap)
                }
        }
    }

    private func panelTouch(_ element: Element) -> some View {
        let count = element.text.components(separatedBy: "\n").count
        return HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Color.clear
                    .frame(width: panelButtonWidth(element))
                    .contentShape(Rectangle())
                    .onTapGesture { pressPanel(element, i) }
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .id(count)
    }

    private func pressPanel(_ element: Element, _ index: Int) {
        fire(element, .tap)
        guard element.tabTargets.indices.contains(index),
              let target = element.tabTargets[index] else { return }
        if let layer = frame.elements.first(where: { $0.id == target }) {
            let show = !isVisible(layer)
            setLayer(layer.id, visible: show)
            if show { raise(layer.id) }
        } else {
            go(Interaction(action: .goTo, screen: target))
        }
    }

    // Opens a screen or shows a layer by its name, for terminal commands.
    private func openNamed(_ name: String) {
        let wanted = name.lowercased()
        if let screen = project.frames.first(where: { $0.name.lowercased() == wanted }) {
            go(Interaction(action: .goTo, screen: screen.id))
        } else if let layer = frame.elements.first(where: {
            $0.name.lowercased() == wanted || $0.text.lowercased() == wanted
        }) {
            setLayer(layer.id, visible: true)
            raise(layer.id)
        }
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
            .modifier(Effects(element: element))
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
            copy.extra = nil
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
        } else if element.kind == .window {
            ElementView(element: shown)
                .overlay(windowTouch(element))
        } else if element.kind == .panel {
            ElementView(element: shown)
                .overlay(panelTouch(shown))
        } else if element.kind == .shell {
            ShellView(element: shown, open: openNamed)
        } else if element.kind == .notes {
            NotesPad(element: shown)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
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
        case .shake:
            withAnimation(.linear(duration: 0.6)) { shakes += 1 }
        case .flash:
            flash()
        case .burst:
            burstStart = Date()
        case .particles:
            particlesOff.toggle()
        case .sound:
            AudioServicesPlaySystemSound(SystemSoundID(item.sound.rawValue))
        case .home:
            var trip = item
            trip.action = .goTo
            trip.screen = (project.frames.first { $0.isHome == true } ?? project.frames.first)?.id
            go(trip)
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
        moved = [:]
        order = [:]
        topOrder = 0
        particlesOff = false
        burstStart = nil
        popup = nil
        progress = 0
        transition = .instant
        layer = UUID()
        current = project.frames.first?.id
        visit += 1
        DispatchQueue.main.async { schedule() }
    }
}
