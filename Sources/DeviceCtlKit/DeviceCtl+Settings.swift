import Foundation
import WrapperSupport

// `device settings`, `device orientation`, `device appResize`, and device-level actions.
extension DeviceCtl {
    // MARK: - Settings

    /// `device settings appearance --mode`. Pass a ``DeviceCtlAppearanceSettings`` to change more than
    /// the interface style.
    ///
    /// **Mutating**.
    public func appearance(_ mode: DeviceCtlAppearance, device: String) -> Self {
        appearance(DeviceCtlAppearanceSettings(mode: mode), device: device)
    }

    /// `device settings appearance`: interface style, look and feel, text size, and the accessibility
    /// display options. Fields left `nil` are not changed.
    ///
    /// **Mutating**.
    public func appearance(_ settings: DeviceCtlAppearanceSettings, device: String) -> Self {
        deviceOperation(["device", "settings", "appearance"], device: device, settings.arguments)
    }

    /// `device settings audio`: the audio devices and volume.
    ///
    /// - Parameters:
    ///   - output: `systemDefault`, or an identifier from ``listAudioDevices()``.
    ///   - input: `systemDefault`, or an identifier from ``listAudioDevices()``.
    ///   - volume: 0 to 100.
    ///
    /// **Mutating**.
    public func audio(output: String? = nil, input: String? = nil, volume: Int? = nil, device: String) -> Self {
        deviceOperation(
            ["device", "settings", "audio"], device: device,
            optionalOption("--output-device", output) + optionalOption("--input-device", input) + optionalNumber("--volume", volume))
    }

    /// `device settings biometrics`. ``DeviceCtlBiometricsAction/query`` only reports enrolment.
    ///
    /// **Mutating** unless `action` is ``DeviceCtlBiometricsAction/query``.
    public func biometrics(_ action: DeviceCtlBiometricsAction = .query, device: String) -> Self {
        deviceOperation(["device", "settings", "biometrics"], device: device, action.arguments)
    }

    /// `device settings standby`: shows or hides StandBy. With `duration`, devicectl presents StandBy,
    /// holds it that long (or until interrupted), then dismisses it.
    ///
    /// **Mutating**.
    public func standby(_ action: DeviceCtlStandbyAction, duration: Double? = nil, device: String) -> Self {
        deviceOperation(
            ["device", "settings", "standby"], device: device,
            ["--\(action.rawValue)"] + optionalNumber("--duration", duration))
    }

    /// `device settings voiceover`: enables or disables VoiceOver.
    ///
    /// **Mutating**.
    public func voiceOver(enabled: Bool, device: String) -> Self {
        deviceOperation(["device", "settings", "voiceover"], device: device, [enabled ? "--enable" : "--disable"])
    }

    /// `device settings reset`: restores factory settings.
    ///
    /// **Mutating and destructive**: erases all user content and files on the device.
    public func resetDevice(device: String) -> Self {
        deviceOperation(["device", "settings", "reset"], device: device)
    }

    // MARK: - Orientation

    /// `device orientation get`.
    public func orientation(device: String) -> Self {
        deviceOperation(["device", "orientation", "get"], device: device)
    }

    /// `device orientation set`.
    ///
    /// **Mutating**.
    public func setOrientation(_ orientation: DeviceCtlOrientation, device: String) -> Self {
        modified(deviceOperation(["device", "orientation", "set"], device: device)) { $0.trailing = [orientation.rawValue] }
    }

    /// `device orientation rotate`: rotates relative to the current orientation.
    ///
    /// **Mutating**.
    public func rotate(_ direction: DeviceCtlRotationDirection, device: String) -> Self {
        modified(deviceOperation(["device", "orientation", "rotate"], device: device)) { $0.trailing = [direction.rawValue] }
    }

    // MARK: - Resizable app sessions

    /// `device appResize observe`: prints resizability state changes until interrupted.
    public func observeAppResize(device: String) -> Self {
        deviceOperation(["device", "appResize", "observe"], device: device)
    }

    /// `device appResize set`: adjusts the active resizable session.
    ///
    /// - Parameters:
    ///   - preferredSize: `<width>x<height>`, e.g. `800x600`.
    ///   - cornerRadius: devicectl defaults to 0.
    ///
    /// **Mutating**.
    public func setAppResize(preferredSize: String, cornerRadius: Double? = nil, device: String) -> Self {
        deviceOperation(
            ["device", "appResize", "set"], device: device,
            ["--preferred-size", preferredSize] + optionalNumber("--corner-radius", cornerRadius))
    }

    /// `device appResize start`: moves the frontmost apps to a resizable display. The session lasts
    /// until the process is interrupted.
    ///
    /// **Mutating**.
    public func startAppResize(preferredSize: String? = nil, cornerRadius: Double? = nil, device: String) -> Self {
        deviceOperation(
            ["device", "appResize", "start"], device: device,
            optionalOption("--preferred-size", preferredSize) + optionalNumber("--corner-radius", cornerRadius))
    }

    // MARK: - Device actions

    /// `device reboot`.
    ///
    /// - Parameters:
    ///   - style: devicectl defaults to a full reboot.
    ///   - waitForDevice: Wait for the device to return; only for physically connected devices.
    ///
    /// **Mutating**.
    public func reboot(style: DeviceCtlRebootStyle? = nil, waitForDevice: Bool = false, device: String) -> Self {
        deviceOperation(
            ["device", "reboot"], device: device,
            optionalOption("--style", style?.rawValue) + flag("--wait-for-device", waitForDevice))
    }

    /// `device rename`.
    ///
    /// **Mutating**.
    public func rename(to name: String, device: String) -> Self {
        deviceOperation(["device", "rename"], device: device, ["--name", name])
    }

    /// `device sysdiagnose`: gathers a sysdiagnose. devicectl rejects `--json-output -` here.
    ///
    /// - Parameters:
    ///   - destination: A host directory; defaults to a unique temporary directory.
    ///   - gatherFullLogs: Ask for full logs, which makes the archive much larger.
    ///   - dryRunOnly: Ask sysdiagnose not to collect anything, for testing.
    public func sysdiagnose(device: String, destination: String? = nil, gatherFullLogs: Bool = false, dryRunOnly: Bool = false) -> Self {
        deviceOperation(
            ["device", "sysdiagnose"], device: device,
            optionalOption("--destination", destination) + flag("--gather-full-logs", gatherFullLogs)
                + flag("--dry-run-only", dryRunOnly))
    }
}
