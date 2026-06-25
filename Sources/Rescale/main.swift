import AppKit
import ServiceManagement

final class ModeChoice: NSObject {
    let displayID: CGDirectDisplayID
    let mode: CGDisplayMode
    let favoriteKey: String

    init(displayID: CGDirectDisplayID, mode: CGDisplayMode, logicalWidth: Int, logicalHeight: Int) {
        self.displayID = displayID
        self.mode = mode
        self.favoriteKey = "\(displayID):\(logicalWidth)x\(logicalHeight)"
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var showAllModes = false
    private var favoritesOnly = false

    private var favorites: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "favorites") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "favorites") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let iconURL = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png", subdirectory: "Resources"),
               let icon = NSImage(contentsOf: iconURL) {
                icon.isTemplate = true
                icon.size = NSSize(width: 16, height: 16)
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Rescale")
            }
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu(menu)
    }

    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let displays = DisplayManager.connectedDisplays(showAll: showAllModes)
        let currentFavorites = favorites
        let hasFavorites = !currentFavorites.isEmpty

        if displays.isEmpty {
            let item = NSMenuItem(title: "No displays found", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        for (index, display) in displays.enumerated() {
            let header = NSMenuItem(title: display.name, action: nil, keyEquivalent: "")
            header.isEnabled = false
            if let firstMode = display.modes.first {
                let isPortrait = firstMode.logicalHeight > firstMode.logicalWidth
                let symbolName = isPortrait ? "rectangle.portrait.fill" : "rectangle.fill"
                if let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: isPortrait ? "Portrait" : "Landscape") {
                    icon.size = NSSize(width: isPortrait ? 9 : 22, height: isPortrait ? 22 : 9)
                    header.image = icon
                }
            }
            menu.addItem(header)

            let currentMode = DisplayManager.currentMode(for: display.id)

            for mode in display.modes {
                let choice = ModeChoice(
                    displayID: display.id,
                    mode: mode.mode,
                    logicalWidth: mode.logicalWidth,
                    logicalHeight: mode.logicalHeight
                )
                let isFavorite = currentFavorites.contains(choice.favoriteKey)

                if favoritesOnly && !isFavorite {
                    continue
                }

                let star = isFavorite ? "★ " : "☆ "
                let item = NSMenuItem(
                    title: "  \(star)\(mode.label)",
                    action: #selector(handleResolutionClick(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = choice

                if let current = currentMode,
                   current.width == mode.logicalWidth,
                   current.height == mode.logicalHeight {
                    item.state = .on
                }

                menu.addItem(item)
            }

            if index < displays.count - 1 {
                menu.addItem(.separator())
            }
        }

        menu.addItem(.separator())

        if hasFavorites {
            let favToggle = NSMenuItem(
                title: "Favorites Only",
                action: #selector(toggleFavoritesOnly),
                keyEquivalent: ""
            )
            favToggle.target = self
            favToggle.state = favoritesOnly ? .on : .off
            menu.addItem(favToggle)
        }

        let toggleItem = NSMenuItem(
            title: "Show All Resolutions",
            action: #selector(toggleShowAll),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = showAllModes ? .on : .off
        menu.addItem(toggleItem)

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let hint = NSMenuItem(title: "⌥-click resolution to favorite", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.menuFont(ofSize: 11),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        hint.attributedTitle = NSAttributedString(string: "⌥-click resolution to favorite", attributes: attributes)
        menu.addItem(hint)

        menu.addItem(.separator())

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let versionItem = NSMenuItem(title: "Rescale v\(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(
            NSMenuItem(
                title: "Quit Rescale",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
    }

    @objc private func handleResolutionClick(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? ModeChoice else { return }

        let optionHeld = NSEvent.modifierFlags.contains(.option)

        if optionHeld {
            var faves = favorites
            if faves.contains(choice.favoriteKey) {
                faves.remove(choice.favoriteKey)
            } else {
                faves.insert(choice.favoriteKey)
            }
            favorites = faves
            DispatchQueue.main.async {
                self.statusItem.button?.performClick(nil)
            }
        } else {
            DisplayManager.applyMode(choice.mode, to: choice.displayID)
        }
    }

    @objc private func toggleShowAll() {
        showAllModes.toggle()
        DispatchQueue.main.async {
            self.statusItem.button?.performClick(nil)
        }
    }

    @objc private func toggleFavoritesOnly() {
        favoritesOnly.toggle()
        DispatchQueue.main.async {
            self.statusItem.button?.performClick(nil)
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Launch at login toggle failed: \(error)")
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
