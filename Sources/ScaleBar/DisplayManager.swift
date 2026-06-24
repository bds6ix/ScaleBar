import AppKit
import CoreGraphics

struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String
}

enum DisplayManager {
    static func connectedDisplays() -> [DisplayInfo] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        // Ask CoreGraphics for all active (non-mirrored, non-sleeping) displays.
        let err = CGGetActiveDisplayList(UInt32(displayIDs.count), &displayIDs, &displayCount)
        guard err == .success else { return [] }

        displayIDs.removeSubrange(Int(displayCount)...)

        return displayIDs.map { cgID in
            let name = screenName(for: cgID) ?? "Display \(cgID)"
            return DisplayInfo(id: cgID, name: name)
        }
    }

    // Bridge from a CGDirectDisplayID to NSScreen to get the human-readable name.
    private static func screenName(for displayID: CGDirectDisplayID) -> String? {
        NSScreen.screens.first {
            $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == displayID
        }?.localizedName
    }
}
