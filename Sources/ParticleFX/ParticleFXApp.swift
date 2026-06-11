import SwiftUI
import AppKit
import SpriteKit
import Combine

@main
struct ParticleFXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 Settings 场景，它不会创建可见窗口
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var overlayManager: OverlayManager?
    private var cancellables = Set<AnyCancellable>()
    var isEnabled: Bool = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Setup Overlay
        overlayManager = OverlayManager()
        overlayManager?.showOverlays()

        // Setup Status Bar Item
        setupStatusItem()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
            updateStatusButton()
        }
        updateMenu()
    }
    
    func updateStatusButton() {
        if let button = statusItem?.button {
            button.alphaValue = isEnabled ? 1.0 : 0.5
            button.image = NSImage(systemSymbolName: isEnabled ? "sparkles" : "sparkles.rectangle.stack", accessibilityDescription: nil)
        }
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // 1. Toggle
        let toggleTitle = isEnabled ? NSLocalizedString("MENU_TOGGLE_DISABLE", bundle: .main, comment: "") : NSLocalizedString("MENU_TOGGLE_ENABLE", bundle: .main, comment: "")
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleAction), keyEquivalent: "t")
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Types
        for (index, type) in ParticleType.allCases.enumerated() {
            let item = NSMenuItem(title: type.localizedName, action: #selector(typeAction(_:)), keyEquivalent: "\(index + 1)")
            item.keyEquivalentModifierMask = [.command]
            item.representedObject = type
            item.state = (AppSettings.shared.currentType == type) ? .on : .off
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Draggable Sliders (The core request)
        menu.addItem(createSliderMenuItem(label: NSLocalizedString("LABEL_DENSITY", bundle: .main, comment: ""), value: Binding(get: { AppSettings.shared.birthRate }, set: { AppSettings.shared.birthRate = $0 }), range: 0...500))
        menu.addItem(createSliderMenuItem(label: NSLocalizedString("LABEL_SPEED", bundle: .main, comment: ""), value: Binding(get: { AppSettings.shared.speed }, set: { AppSettings.shared.speed = $0 }), range: 10...1000))
        menu.addItem(createSliderMenuItem(label: NSLocalizedString("LABEL_SCALE", bundle: .main, comment: ""), value: Binding(get: { AppSettings.shared.scale }, set: { AppSettings.shared.scale = $0 }), range: 0.01...1.0, format: "%.2f"))
        menu.addItem(createSliderMenuItem(label: NSLocalizedString("LABEL_SIZE_RANGE", bundle: .main, comment: ""), value: Binding(get: { AppSettings.shared.scaleRange }, set: { AppSettings.shared.scaleRange = $0 }), range: 0.0...0.5, format: "%.2f"))
        menu.addItem(createSliderMenuItem(label: NSLocalizedString("LABEL_OPACITY", bundle: .main, comment: ""), value: Binding(get: { AppSettings.shared.opacity }, set: { AppSettings.shared.opacity = $0 }), range: 0.1...1.0, format: "%.0f", unit: "%", multiplier: 100))
        menu.addItem(createSliderMenuItem(label: NSLocalizedString("LABEL_WIND", bundle: .main, comment: ""), value: Binding(get: { AppSettings.shared.windX }, set: { AppSettings.shared.windX = $0 }), range: -5...5, format: "%.1f"))
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Level (Flattened)
        for level in OverlayLevel.allCases {
            let item = NSMenuItem(title: level.localizedName, action: #selector(levelAction(_:)), keyEquivalent: "")
            item.representedObject = level
            item.state = (AppSettings.shared.level == level) ? .on : .off
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Quit
        menu.addItem(NSMenuItem(title: NSLocalizedString("MENU_QUIT", bundle: .main, comment: ""), action: #selector(quitAction), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func createSliderMenuItem(label: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, format: String = "%.0f", unit: String = "", multiplier: CGFloat = 1.0) -> NSMenuItem {
        let item = NSMenuItem()
        let view = MenuSliderWrapper(label: label, value: value, range: range, format: format, unit: unit, multiplier: multiplier)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 250, height: 30)
        item.view = hostingView
        return item
    }
    
    @objc func toggleAction() {
        isEnabled.toggle()
        toggleOverlay(isEnabled)
        updateStatusButton()
        updateMenuStates()
    }

    @objc func typeAction(_ sender: NSMenuItem) {
        if let type = sender.representedObject as? ParticleType {
            AppSettings.shared.currentType = type
            updateMenuStates()
        }
    }

    @objc func levelAction(_ sender: NSMenuItem) {
        if let level = sender.representedObject as? OverlayLevel {
            AppSettings.shared.level = level
            updateWindowLevel()
            updateMenuStates()
        }
    }
    
    @objc func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    func updateWindowLevel() {
        overlayManager?.updateLevel()
    }

    func toggleOverlay(_ enabled: Bool) {
        if enabled {
            overlayManager?.showOverlays()
        } else {
            overlayManager?.hideOverlays()
        }
    }

    func updateMenuStates() {
        guard let menu = statusItem?.menu else { return }
        for item in menu.items {
            switch item.action {
            case #selector(toggleAction):
                item.title = isEnabled
                    ? NSLocalizedString("MENU_TOGGLE_DISABLE", bundle: .main, comment: "")
                    : NSLocalizedString("MENU_TOGGLE_ENABLE", bundle: .main, comment: "")
            case #selector(typeAction(_:)):
                if let type = item.representedObject as? ParticleType {
                    item.state = (AppSettings.shared.currentType == type) ? .on : .off
                }
            case #selector(levelAction(_:)):
                if let level = item.representedObject as? OverlayLevel {
                    item.state = (AppSettings.shared.level == level) ? .on : .off
                }
            default:
                break
            }
        }
    }
}

struct MenuSliderWrapper: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let format: String
    let unit: String
    let multiplier: CGFloat
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 60, alignment: .leading)
            
            Slider(value: $value, in: range)
                .controlSize(.small)
            
            Text(String(format: format, value * multiplier) + unit)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 45, alignment: .trailing)
        }
        .padding(.horizontal, 10)
    }
}

class OverlayManager {
    var windows: [NSWindow] = []

    init() {
        createWindows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func screenParametersChanged() {
        hideOverlays()
        windows.forEach { $0.close() }
        windows.removeAll()
        createWindows()
        showOverlays()
    }

    private func createWindows() {
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.level = AppSettings.shared.level.nsLevel

            let contentView = NSHostingView(rootView: ParticleLayerView())
            window.contentView = contentView
            windows.append(window)
        }
    }

    func updateLevel() {
        for window in windows {
            window.level = AppSettings.shared.level.nsLevel
        }
    }

    func showOverlays() {
        for window in windows {
            window.orderFrontRegardless()
        }
    }

    func hideOverlays() {
        for window in windows {
            window.orderOut(nil)
        }
    }
}

struct ParticleLayerView: View {
    @ObservedObject var settings = AppSettings.shared
    
    @State private var mainScene: MainParticleScene = {
        let s = MainParticleScene()
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        return s
    }()
    
    var body: some View {
        SpriteView(scene: mainScene, options: [.allowsTransparency])
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
    }
}
