import Foundation
import WrapperSupport

// `device info`: read-only queries about one device.
extension DeviceCtl {
    /// `device info details`.
    public func details(device: String) -> Self {
        deviceOperation(["device", "info", "details"], device: device)
    }

    /// `device info apps`, optionally limited to one bundle identifier.
    public func apps(
        device: String,
        bundleID: String? = nil,
        options: DeviceCtlAppListOptions = .init(),
        filter: DeviceCtlFilterOptions = .init()
    ) -> Self {
        deviceOperation(
            ["device", "info", "apps"], device: device,
            options.arguments + optionalOption("--bundle-id", bundleID) + filter.arguments)
    }

    /// `device info processes`.
    public func processes(device: String, filter: DeviceCtlFilterOptions = .init()) -> Self {
        deviceOperation(["device", "info", "processes"], device: device, filter.arguments)
    }

    /// `device info displays`. With `stream`, devicectl prints the value on subscription and on every
    /// change until interrupted.
    public func displays(device: String, stream: Bool = false) -> Self {
        deviceOperation(["device", "info", "displays"], device: device, flag("--stream", stream))
    }

    /// `device info files`: lists files in a domain on the device.
    ///
    /// - Parameters:
    ///   - username: The user to target; only relevant for some domains.
    ///   - subdirectory: A directory within the domain; defaults to its root.
    ///   - recurse: Descend into subdirectories; devicectl recurses by default.
    public func files(
        device: String,
        domain: DeviceCtlFileDomain,
        username: String? = nil,
        subdirectory: String? = nil,
        recurse: Bool? = nil,
        filter: DeviceCtlFilterOptions = .init()
    ) -> Self {
        deviceOperation(
            ["device", "info", "files"], device: device,
            domain.arguments + optionalOption("--username", username) + optionalOption("--subdirectory", subdirectory)
                + toggle("recurse", recurse) + filter.arguments)
    }

    /// `device info appIcon`: asks the device to render an installed app's icon.
    ///
    /// The device returns only sizes it supports, so the result may differ from the request. Give
    /// `bundleID` or `appPath`; when both are given devicectl uses `appPath`.
    ///
    /// - Parameters:
    ///   - allowPlaceholder: Permit placeholder icons, which need no I/O on the device.
    ///   - destination: A host path to write the PNG to.
    public func appIcon(
        device: String,
        bundleID: String? = nil,
        appPath: String? = nil,
        allowPlaceholder: Bool? = nil,
        width: Double? = nil,
        height: Double? = nil,
        scale: Double? = nil,
        destination: String? = nil
    ) -> Self {
        deviceOperation(
            ["device", "info", "appIcon"], device: device,
            optionalOption("--app-bundle-id", bundleID) + optionalOption("--app-path", appPath)
                + (allowPlaceholder.map { ["--allow-placeholder", $0 ? "true" : "false"] } ?? [])
                + optionalNumber("--width", width) + optionalNumber("--height", height) + optionalNumber("--scale", scale)
                + optionalOption("--destination", destination))
    }

    /// `device info appResize`: the state of the active resizable app session. Fails without one.
    public func appResizeInfo(device: String) -> Self {
        deviceOperation(["device", "info", "appResize"], device: device)
    }

    /// `device info appearance`: the current interface style and accessibility display settings.
    public func appearanceInfo(device: String) -> Self {
        deviceOperation(["device", "info", "appearance"], device: device)
    }

    /// `device info audio`: the current output and input devices and volume.
    public func audioInfo(device: String) -> Self {
        deviceOperation(["device", "info", "audio"], device: device)
    }

    /// `device info authListing`: the identifiers needed to AuthList the device with TATSU.
    public func authListing(device: String) -> Self {
        deviceOperation(["device", "info", "authListing"], device: device)
    }

    /// `device info ddiServices`: the developer disk image services on the device.
    ///
    /// - Parameter autoMountDDIs: Check and update the mounted DDI first; devicectl does by default.
    ///   **Mutating** unless `false`.
    public func ddiServices(device: String, autoMountDDIs: Bool? = nil) -> Self {
        deviceOperation(["device", "info", "ddiServices"], device: device, toggle("auto-mount-ddis", autoMountDDIs))
    }

    /// `device info lockState`: whether the device is locked. Does nothing for macOS.
    public func lockState(device: String) -> Self {
        deviceOperation(["device", "info", "lockState"], device: device)
    }

    /// `device info mountpoint`: the host path of the device's data folder, mounting the file system if needed.
    public func mountpoint(device: String) -> Self {
        deviceOperation(["device", "info", "mountpoint"], device: device)
    }

    /// `device info standby`: whether StandBy is showing.
    public func standbyInfo(device: String) -> Self {
        deviceOperation(["device", "info", "standby"], device: device)
    }

    /// `device info voiceover`: whether VoiceOver is enabled.
    public func voiceOverInfo(device: String) -> Self {
        deviceOperation(["device", "info", "voiceover"], device: device)
    }
}
