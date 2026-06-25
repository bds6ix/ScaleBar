import AppKit

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

            for mode in display.modes {
                let item = NSMenuItem(title: "  \(mode.label)", action: nil, keyEquivalent: "")
                item.isEnabled = false
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

    @objc private func toggleShowAll() {
        showAllModes.toggle()
        rebuildMenu()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
