import Foundation
import WrapperSupport

// Commands that describe or manage the host's view of devices: `list`, `manage`, and `diagnose`.
extension DeviceCtl {
    // MARK: - list

    /// `list devices`. Xcode 27 also lists simulators; each row's `reality` says which it is.
    public func listDevices(filter: DeviceCtlFilterOptions = .init()) -> Self {
        operation(["list", "devices"] + filter.arguments)
    }

    /// `list audioDevices`: the host's audio inputs and outputs, for ``audio(output:input:volume:device:)``.
    public func listAudioDevices() -> Self {
        operation(["list", "audioDevices"])
    }

    /// `list plugins`: the plugins devicectl and CoreDeviceService loaded.
    public func listPlugins() -> Self {
        operation(["list", "plugins"])
    }

    /// `list preferredDDI`: the developer disk image CoreDevice would use for `platform`, or for
    /// every platform when `nil`.
    public func listPreferredDDI(platform: String? = nil) -> Self {
        operation(["list", "preferredDDI"] + optionalOption("--platform", platform))
    }

    // MARK: - manage

    /// `manage ddis clean`.
    ///
    /// **Mutating**: removes every developer disk image in `/Library/Developer/DeveloperDiskImages`.
    public func manageDDIsClean() -> Self {
        operation(["manage", "ddis", "clean"])
    }

    /// `manage ddis update`.
    ///
    /// **Mutating**: changes the developer disk images installed on the host.
    ///
    /// - Parameters:
    ///   - sourceDirectories: Absolute paths of directories of DDIs to install instead of Xcode's.
    ///   - clean: Empty `/Library/Developer/DeveloperDiskImages` first.
    ///   - includeCoreDevice: Consider `/Library/Developer/CoreDevice/CandidateDDIs`.
    ///   - includeXcode: Consider the selected Xcode's DDIs.
    public func manageDDIsUpdate(
        sourceDirectories: [String] = [],
        clean: Bool? = nil,
        includeCoreDevice: Bool? = nil,
        includeXcode: Bool? = nil
    ) -> Self {
        operation(
            ["manage", "ddis", "update"] + repeated("--source-dir", sourceDirectories) + toggle("clean", clean)
                + toggle("include-coredevice", includeCoreDevice) + toggle("include-xcode", includeXcode))
    }

    /// `manage loggingProfile register`.
    ///
    /// **Mutating**: registers a logging profile on the host that the user then activates in System Settings.
    public func registerLoggingProfile() -> Self {
        operation(["manage", "loggingProfile", "register"])
    }

    /// `manage pair`: pairs the host with a device CoreDevice discovered.
    ///
    /// **Mutating**: may prompt on the device.
    public func pairDevice(device: String, columns: DeviceCtlColumnOptions = .init()) -> Self {
        deviceOperation(["manage", "pair"], device: device, columns.arguments)
    }

    /// `manage unpair`: unpairs a manually paired device.
    ///
    /// **Mutating**.
    public func unpairDevice(device: String, columns: DeviceCtlColumnOptions = .init()) -> Self {
        deviceOperation(["manage", "unpair"], device: device, columns.arguments)
    }

    // MARK: - diagnose

    /// `diagnose`: gathers host and device diagnostics into a ZIP archive. devicectl waits up to 3600
    /// seconds by default, and rejects `--json-output -`.
    ///
    /// - Parameters:
    ///   - finder: Reveal the archive in Finder; pass `false` for headless runs.
    ///   - keepTempDirectory: Keep the working directory after archiving.
    ///   - archiveDestination: Where to write the ZIP; defaults to `/tmp/devicectl_diagnose_<timestamp>.zip`.
    ///   - archive: Pass `false` to leave the collected files uncompressed.
    ///   - includeHostSysdiagnose: Include the slower host sysdiagnose.
    public func diagnose(
        finder: Bool? = nil,
        keepTempDirectory: Bool = false,
        archiveDestination: String? = nil,
        archive: Bool? = nil,
        includeHostSysdiagnose: Bool? = nil
    ) -> Self {
        operation(
            ["diagnose"] + toggle("finder", finder) + flag("--keep-temp-dir", keepTempDirectory)
                + optionalOption("--archive-destination", archiveDestination) + toggle("archive", archive)
                + toggle("include-host-sysdiagnose", includeHostSysdiagnose))
    }
}
