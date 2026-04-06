import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var currentType: ParticleType = .snow { didSet { save() } }
    @Published var birthRate: CGFloat = 50.0 { didSet { save() } }
    @Published var speed: CGFloat = 100.0 { didSet { save() } }
    @Published var scale: CGFloat = 0.1 { didSet { save() } }
    @Published var scaleRange: CGFloat = 0.05 { didSet { save() } }
    @Published var opacity: CGFloat = 0.7 { didSet { save() } }
    @Published var windX: CGFloat = 0.0 { didSet { save() } }
    @Published var level: OverlayLevel = .belowWindows { didSet { save() } }
    
    @Published var particleColor: Color = .white {
        didSet {
            if let components = NSColor(particleColor).cgColor.components {
                UserDefaults.standard.set(components, forKey: "particleColor")
            }
        }
    }
    
    private init() {
        load()
    }
    
    private func save() {
        UserDefaults.standard.set(currentType.rawValue, forKey: "currentType")
        UserDefaults.standard.set(birthRate, forKey: "birthRate")
        UserDefaults.standard.set(speed, forKey: "speed")
        UserDefaults.standard.set(scale, forKey: "scale")
        UserDefaults.standard.set(scaleRange, forKey: "scaleRange")
        UserDefaults.standard.set(opacity, forKey: "opacity")
        UserDefaults.standard.set(windX, forKey: "windX")
        UserDefaults.standard.set(level.rawValue, forKey: "level")
    }
    
    private func load() {
        if let typeStr = UserDefaults.standard.string(forKey: "currentType"), let type = ParticleType(rawValue: typeStr) {
            currentType = type
        }
        if UserDefaults.standard.object(forKey: "birthRate") != nil { birthRate = CGFloat(UserDefaults.standard.double(forKey: "birthRate")) }
        if UserDefaults.standard.object(forKey: "speed") != nil { speed = CGFloat(UserDefaults.standard.double(forKey: "speed")) }
        if UserDefaults.standard.object(forKey: "scale") != nil { scale = CGFloat(UserDefaults.standard.double(forKey: "scale")) }
        if UserDefaults.standard.object(forKey: "scaleRange") != nil { scaleRange = CGFloat(UserDefaults.standard.double(forKey: "scaleRange")) }
        if UserDefaults.standard.object(forKey: "opacity") != nil { opacity = CGFloat(UserDefaults.standard.double(forKey: "opacity")) }
        if UserDefaults.standard.object(forKey: "windX") != nil { windX = CGFloat(UserDefaults.standard.double(forKey: "windX")) }
        if let levelStr = UserDefaults.standard.string(forKey: "level"), let l = OverlayLevel(rawValue: levelStr) {
            level = l
        }
        if let components = UserDefaults.standard.array(forKey: "particleColor") as? [CGFloat], components.count >= 3 {
            particleColor = Color(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components.count > 3 ? components[3] : 1.0)
        }
    }
}

enum ParticleType: String, CaseIterable {
    case snow = "Snow"
    case sakura = "Sakura"
    case leaves = "Leaves"
    case fireflies = "Fireflies"
    
    var icon: String {
        switch self {
        case .snow: return "snowflake"
        case .sakura: return "leaf"
        case .leaves: return "laurel.leading"
        case .fireflies: return "ant"
        }
    }
    
    var localizedName: String {
        switch self {
        case .snow: return NSLocalizedString("TYPE_SNOW", bundle: .main, comment: "")
        case .sakura: return NSLocalizedString("TYPE_SAKURA", bundle: .main, comment: "")
        case .leaves: return NSLocalizedString("TYPE_LEAVES", bundle: .main, comment: "")
        case .fireflies: return NSLocalizedString("TYPE_FIREFLIES", bundle: .main, comment: "")
        }
    }
}

enum OverlayLevel: String, CaseIterable {
    case alwaysOnTop = "Always on Top"
    case belowWindows = "Below Windows"
    
    var localizedName: String {
        switch self {
        case .alwaysOnTop: return NSLocalizedString("LEVEL_TOP", bundle: .main, comment: "")
        case .belowWindows: return NSLocalizedString("LEVEL_BELOW", bundle: .main, comment: "")
        }
    }
    
    var nsLevel: NSWindow.Level {
        switch self {
        case .alwaysOnTop:
            return .floating
        case .belowWindows:
            return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        }
    }
}
