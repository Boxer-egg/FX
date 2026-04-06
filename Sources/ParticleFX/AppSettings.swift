import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var currentType: ParticleType = .snow
    @Published var birthRate: CGFloat = 50.0
    @Published var speed: CGFloat = 100.0
    @Published var scale: CGFloat = 0.1
    @Published var opacity: CGFloat = 0.7
    @Published var level: OverlayLevel = .belowWindows
    
    private init() {}
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
