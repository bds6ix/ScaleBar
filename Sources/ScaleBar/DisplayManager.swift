import AppKit
import CoreGraphics

struct DisplayInfo {
    let id: CGDirectDisplayID
    let name: String
    let modes: [ScaledMode]
}

struct ScaledMode {
    let mode: CGDisplayMode
    let logicalWidth: Int
    let logicalHeight: Int

    var label: String {
        "\(logicalWidth) × \(logicalHeight)"
    }
}

enum DisplayManager {
    static func connectedDisplays(showAll: Bool = false) -> [DisplayInfo] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        let err = CGGetActiveDisplayList(UInt32(displayIDs.count), &displayIDs, &displayCount)
        guard err == .success else { return [] }

        displayIDs.removeSubrange(Int(displayCount)...)

        return displayIDs.map { cgID in
            let name = screenName(for: cgID) ?? "Display \(cgID)"
            let modes = scaledModes(for: cgID, showAll: showAll)
            return DisplayInfo(id: cgID, name: name, modes: modes)
        }
    }

    static func scaledModes(for displayID: CGDirectDisplayID, showAll: Bool) -> [ScaledMode] {
        let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary

        guard let allModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return []
        }

        // Find the true native resolution: the largest 1:1 (LoDPI) mode where pixelWidth == width.
        let nativeMode = allModes
            .filter { $0.pixelWidth == $0.width && $0.isUsableForDesktopGUI() }
            .max(by: { $0.width < $1.width })
        let nativeWidth = nativeMode?.width ?? 3840
        let nativeHeight = nativeMode?.height ?? 2160
        let halfNativeWidth = nativeWidth / 2
        let nativeAspect = Double(nativeWidth) / Double(nativeHeight)

        var seen = Set<String>()
        var result: [ScaledMode] = []

        for mode in allModes {
            guard mode.isUsableForDesktopGUI() else { continue }

            let pixelWidth = mode.pixelWidth
            let pointWidth = mode.width
            let pointHeight = mode.height

            guard pixelWidth > pointWidth else { continue }

            let key = "\(pointWidth)x\(pointHeight)"
            guard seen.insert(key).inserted else { continue }

            if !showAll {
                let modeAspect = Double(pointWidth) / Double(pointHeight)
                guard abs(modeAspect - nativeAspect) < 0.01 else { continue }
                guard pointWidth >= halfNativeWidth else { continue }
            }

            result.append(ScaledMode(
                mode: mode,
                logicalWidth: pointWidth,
                logicalHeight: pointHeight
            ))
        }

        // Include the 1:1 native mode (LoDPI — pixelWidth == width).
        if let nativeMode = nativeMode {
            let nativeKey = "\(nativeWidth)x\(nativeHeight)"
            if seen.insert(nativeKey).inserted {
                result.append(ScaledMode(
                    mode: nativeMode,
                    logicalWidth: nativeWidth,
                    logicalHeight: nativeHeight
                ))
            }
        }

        result.sort { $0.logicalWidth < $1.logicalWidth }

        return result
    }

    static func applyMode(_ mode: CGDisplayMode, to displayID: CGDirectDisplayID) {
        var config: CGDisplayConfigRef?
        let beginErr = CGBeginDisplayConfiguration(&config)
        guard beginErr == .success, let config = config else { return }

        CGConfigureDisplayWithDisplayMode(config, displayID, mode, nil)

        let completeErr = CGCompleteDisplayConfiguration(config, .permanently)
        if completeErr != .success {
            CGCancelDisplayConfiguration(config)
        }
    }

    static func currentMode(for displayID: CGDirectDisplayID) -> CGDisplayMode? {
        CGDisplayCopyDisplayMode(displayID)
    }

    private static func screenName(for displayID: CGDirectDisplayID) -> String? {
        NSScreen.screens.first {
            $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == displayID
        }?.localizedName
    }
}
