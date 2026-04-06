import SwiftUI
import AppKit
import SpriteKit
import Combine

@main
struct ParticleFXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var settings = AppSettings.shared
    @State private var isEnabled: Bool = true
    
    var body: some Scene {
        MenuBarExtra {
            Button(isEnabled ? NSLocalizedString("MENU_TOGGLE_DISABLE", bundle: .main, comment: "") : NSLocalizedString("MENU_TOGGLE_ENABLE", bundle: .main, comment: "")) {
                isEnabled.toggle()
                appDelegate.toggleOverlay(isEnabled)
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            
            Divider()
            
            Section(NSLocalizedString("MENU_SECTION_TYPE", bundle: .main, comment: "")) {
                ForEach(ParticleType.allCases, id: \.self) { type in
                    Button {
                        settings.currentType = type
                    } label: {
                        HStack {
                            Text(type.localizedName)
                            if settings.currentType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Section(NSLocalizedString("MENU_SECTION_LEVEL", bundle: .main, comment: "")) {
                ForEach(OverlayLevel.allCases, id: \.self) { level in
                    Button {
                        settings.level = level
                        appDelegate.updateWindowLevel()
                    } label: {
                        HStack {
                            Text(level.localizedName)
                            if settings.level == level {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Button(NSLocalizedString("MENU_SETTINGS", bundle: .main, comment: "")) {
                appDelegate.showSettings()
            }
            .keyboardShortcut(",") // Standard macOS shortcut for Settings (Cmd + ,)
            
            Divider()
            Button(NSLocalizedString("MENU_QUIT", bundle: .main, comment: "")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            // 使用自定义 Label 确保图标在禁用时不会消失
            Image(systemName: "sparkles")
                .symbolVariant(isEnabled ? .none : .slash) // 禁用时显示斜杠
                .opacity(isEnabled ? 1.0 : 0.5) // 禁用时半透明
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var overlayController: OverlayController?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlayController = OverlayController()
        overlayController?.showOverlay()
    }
    
    func updateWindowLevel() {
        overlayController?.updateLevel()
    }
    
    func toggleOverlay(_ enabled: Bool) {
        if enabled {
            overlayController?.showOverlay()
        } else {
            overlayController?.hideOverlay()
        }
    }
    
    func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = NSLocalizedString("WINDOW_TITLE", comment: "")
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

class OverlayController {
    var window: NSWindow?
    
    init() {
        let screenRect = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: screenRect,
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
        self.window = window
    }
    
    func updateLevel() {
        window?.level = AppSettings.shared.level.nsLevel
    }
    
    func showOverlay() {
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
    
    func hideOverlay() {
        window?.orderOut(nil)
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
