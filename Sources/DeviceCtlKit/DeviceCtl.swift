import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for `xcrun devicectl`, Apple's CLI for CoreDevice: physical devices and, from
/// Xcode 27, simulators.
///
/// `devicectl` is not `simctl` for hardware: it addresses devices by CoreDevice identifier, UDID,
/// ECID, serial number, name, or DNS name, reports through `--json-output`, and has no port
/// forwarding (use `IProxyKit`).
///
/// Every leaf command of `devicectl device`, `list`, `manage`, and `diagnose` is modelled across
/// the `DeviceCtl+*.swift` extensions, grouped the way devicectl groups them:
///
/// | Group | Operations |
/// | --- | --- |
/// | Inventory | `listDevices`, `listAudioDevices`, `listPlugins`, `listPreferredDDI` |
/// | `device info` | `details`, `apps`, `processes`, `displays`, `files`, `appIcon`, `appearanceInfo`, `audioInfo`, `ddiServices`, `lockState`, `mountpoint`, `standbyInfo`, `voiceOverInfo`, `authListing`, `appResizeInfo` |
/// | Apps and processes | `install`, `uninstall`, `launch`, `openURL`, `signal`, `terminate`, `suspend`, `resume`, `sendMemoryWarning`, `awaitTermination` |
/// | Files | `copyToDevice`, `copyFromDevice` |
/// | Capture | `screenshot`, `screenRecord` |
/// | Settings | `appearance`, `audio`, `biometrics`, `orientation`, `standby`, `voiceOver`, `resetDevice` |
/// | Simulation | `simulateLocation`, `simulateStatusBar`, `simulateBiometrics` |
/// | Pasteboard and notifications | `pasteboard…`, `postNotifications`, `observeNotifications` |
/// | Profiles, pairing, host | `profile…`, `pairings…`, `pairDevice`, `unpairDevice`, `manageDDIs…`, `diagnose`, `sysdiagnose`, `reboot`, `rename` |
///
/// ```swift
/// let output = try await DeviceCtl(context: shell)
///     .launch(bundleID: "com.example.app", device: udid, terminateExisting: true)
///     .run()
/// ```
///
/// Operations that never end on their own (`--console`, `observe`, `monitor`, `sync-with-host`,
/// `screen-record` without a duration, `appResize start`) are still plain argv; the caller decides
/// whether to run them with a timeout or spawn and tear them down.
public struct DeviceCtl: RunnableCommandFamily {
    var spec: CommandSpec
    var jsonOutput: String?
    var timeoutSeconds: Int?
    var quiet = false
    var verbose = false
    var omitDeprecatedFields = false
    var logOutput: String?
    /// Positional values that must follow every option, e.g. a launched app's bundle id and argv.
    var trailing: [String] = []
    /// Whether `--` precedes ``trailing``, ending devicectl's own options so app arguments such as
    /// `-v` are not claimed by devicectl.
    var terminatesOptions = false

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates a `devicectl` command family that runs through `xcrun`.
    public init(context: ShellContext = .init()) {
        self.spec = CommandSpec(executable: "xcrun", prefix: ["devicectl"], context: context)
    }

    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    // MARK: - Global options

    /// Writes the machine-readable result to `path`; `-` writes it to stdout.
    ///
    /// A failed command still writes its JSON, including an `error` object with the CoreDevice
    /// error code. Commands that write payloads to stdout (`pasteboard paste`, `launch --console`,
    /// `sysdiagnose`, `diagnose`) reject `-`; pass a file path to those.
    public func jsonOutput(_ path: String = "-") -> Self {
        modified(self) { $0.jsonOutput = path }
    }

    /// Fails the operation after `seconds` (`--timeout`).
    public func deviceTimeout(seconds: Int) -> Self {
        modified(self) { $0.timeoutSeconds = seconds }
    }

    /// Suppresses progress output (`--quiet`).
    public func quiet(_ enabled: Bool = true) -> Self {
        modified(self) { $0.quiet = enabled }
    }

    /// Requests more logging output than normal (`--verbose`).
    public func verbose(_ enabled: Bool = true) -> Self {
        modified(self) { $0.verbose = enabled }
    }

    /// Drops fields devicectl has deprecated from the JSON output (`--omit-deprecated-fields-in-json`).
    public func omitDeprecatedFieldsInJSON(_ enabled: Bool = true) -> Self {
        modified(self) { $0.omitDeprecatedFields = enabled }
    }

    /// Writes everything otherwise sent to stdout and stderr to `path` (`--log-output`).
    public func logOutput(_ path: String) -> Self {
        modified(self) { $0.logOutput = path }
    }

    /// Any `devicectl` subcommand this wrapper does not model, such as one a future Xcode adds.
    public func custom(_ arguments: [String]) -> Self {
        operation(arguments)
    }

    /// Builds the raw `xcrun devicectl` command.
    public func command() -> Command {
        var built = spec
        built.arguments += optionalOption("--json-output", jsonOutput)
        built.arguments += timeoutSeconds.map { ["--timeout", String($0)] } ?? []
        built.arguments += flag("--quiet", quiet)
        built.arguments += flag("--verbose", verbose)
        built.arguments += flag("--omit-deprecated-fields-in-json", omitDeprecatedFields)
        built.arguments += optionalOption("--log-output", logOutput)
        built.arguments += terminatesOptions && !trailing.isEmpty ? ["--"] : []
        built.arguments += trailing
        return built.command()
    }

    // MARK: - Builders shared by the operation extensions

    /// Selects `values` as the operation, dropping the previous operation's positionals.
    func operation(_ values: [String]) -> Self {
        modified(self) {
            $0.spec.arguments = values
            $0.trailing = []
            $0.terminatesOptions = false
        }
    }

    /// Selects an operation on one device: `<path> --device <device> <options>`.
    func deviceOperation(_ path: [String], device: String, _ options: [String] = []) -> Self {
        operation(path + ["--device", device] + options)
    }

    static func jsonObject(_ values: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
            let text = String(bytes: data, encoding: .utf8)
        else { return "{}" }
        return text
    }
}

/// Appends `--name` or `--no-name` for a boolean the tool declares as `--name/--no-name`; `nil`
/// leaves the tool's own default.
func toggle(_ name: String, _ value: Bool?) -> [String] {
    guard let value else { return [] }
    return [value ? "--\(name)" : "--no-\(name)"]
}

/// Appends `name on` or `name off` for an option that takes `on` or `off`.
func onOff(_ name: String, _ value: Bool?) -> [String] {
    value.map { [name, $0 ? "on" : "off"] } ?? []
}

/// Appends `name value` once per value, for options that repeat.
func repeated(_ name: String, _ values: [String]) -> [String] {
    values.flatMap { [name, $0] }
}

/// Appends `name` and a number when present.
func optionalNumber<Number: CustomStringConvertible>(_ name: String, _ value: Number?) -> [String] {
    value.map { [name, $0.description] } ?? []
}
