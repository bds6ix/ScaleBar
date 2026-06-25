import AppKit

// Bundles a display ID and mode together so a menu item knows what to apply.
final class ModeChoice: NSObject {
    let displayID: CGDirectDisplayID
    let mode: CGDisplayMode

    init(displayID: CGDirectDisplayID, mode: CGDisplayMode) {
        self.displayID = displayID
        self.mode = mode
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var showAllModes = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "ScaleBar")
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let displays = DisplayManager.connectedDisplays(showAll: showAllModes)
        for (index, display) in displays.enumerated() {
            let header = NSMenuItem(title: display.name, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            let currentMode = DisplayManager.currentMode(for: display.id)

            for mode in display.modes {
                let item = NSMenuItem(
                    title: "  \(mode.label)",
                    action: #selector(applyResolution(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = ModeChoice(displayID: display.id, mode: mode.mode)

                // Checkmark the active resolution.
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

        let toggleItem = NSMenuItem(
            title: "Show All Resolutions",
            action: #selector(toggleShowAll),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = showAllModes ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit ScaleBar",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        statusItem.menu = menu
    }

    @objc private func applyResolution(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? ModeChoice else { return }
        DisplayManager.applyMode(choice.mode, to: choice.displayID)
        rebuildMenu()
    }

    @objc private func toggleShowAll() {
        showAllModes.toggle()
        rebuildMenu()
        // Reopen the menu so the user sees the change without an extra click.
        DispatchQueue.main.async {
            self.statusItem.button?.performClick(nil)
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
