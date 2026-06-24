import AppKit

// AppKit needs a delegate object to own the menu bar item and stay alive to
// respond to clicks. Everything the app "is" hangs off this one object for now.
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Held as a property so ARC doesn't deallocate the menu bar item after launch.
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Claim a slot in the system menu bar. .variableLength lets it size to its content.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // The clickable part. Use an SF Symbol so it looks native in light/dark mode.
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "ScaleBar")
        }

        // The walking skeleton can do exactly one thing: quit.
        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Quit ScaleBar",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        statusItem.menu = menu
    }
}

// Manual app bootstrap (no storyboard, no @main). main.swift is the entry point.
let app = NSApplication.shared

// .accessory = no Dock icon, no app menu — a background menu bar agent.
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate   // strong reference; lives as long as the program runs
app.run()                 // hand control to the AppKit event loop (blocks here)
