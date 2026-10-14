import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for `xcrun devicectl`, Apple's CLI for physical devices (CoreDevice).
///
/// `devicectl` is not `simctl` for hardware: it addresses devices by CoreDevice identifier, UDID,
/// or name, reports through `--json-output`, and has no port forwarding (use `IProxyKit`).
///
/// ```swift
/// let output = try await DeviceCtl(context: shell)
///     .launch(bundleID: "com.example.app", device: udid, terminateExisting: true)
///     .run()
/// ```
public struct DeviceCtl: RunnableCommandFamily {
    private var spec: CommandSpec
    private var jsonOutput: String?
    private var timeoutSeconds: Int?
    private var quiet = false
    /// Positional values that must follow every option, e.g. a launched app's bundle id and argv.
    private var trailing: [String] = []

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

    // MARK: - Inventory

    /// `list devices`.
    public func listDevices() -> Self {
        operation(["list", "devices"])
    }

    /// `device info details`.
    public func details(device: String) -> Self {
        operation(["device", "info", "details", "--device", device])
    }

    /// `device info apps`, optionally limited to one bundle identifier.
    public func apps(device: String, bundleID: String? = nil) -> Self {
        operation(["device", "info", "apps", "--device", device] + optionalOption("--bundle-id", bundleID))
    }

    /// `device info processes`.
    public func processes(device: String) -> Self {
        operation(["device", "info", "processes", "--device", device])
    }

    // MARK: - Apps

    /// `device install app`.
    public func install(appPath: String, device: String) -> Self {
        operation(["device", "install", "app", "--device", device, appPath])
    }

    /// `device uninstall app`.
    public func uninstall(bundleID: String, device: String) -> Self {
        operation(["device", "uninstall", "app", "--device", device, bundleID])
    }

    /// `device process launch`.
    ///
    /// - Parameters:
    ///   - environment: Encoded as the JSON object `--environment-variables` expects.
    ///   - arguments: Passed to the app after its bundle identifier.
    public func launch(
        bundleID: String,
        device: String,
        terminateExisting: Bool = false,
        console: Bool = false,
        startStopped: Bool = false,
        environment: [String: String] = [:],
        payloadURL: String? = nil,
        arguments: [String] = []
    ) -> Self {
        var values = ["device", "process", "launch", "--device", device]
        values += flag("--terminate-existing", terminateExisting)
        values += flag("--console", console)
        values += flag("--start-stopped", startStopped)
        if !environment.isEmpty {
            values += ["--environment-variables", Self.jsonObject(environment)]
        }
        values += optionalOption("--payload-url", payloadURL)
        return modified(operation(values)) { $0.trailing = [bundleID] + arguments }
    }

    /// `device process signal`.
    public func signal(_ signal: String = "SIGTERM", pid: Int32, device: String) -> Self {
        operation(["device", "process", "signal", "--device", device, "--pid", String(pid), "--signal", signal])
    }

    /// `device process terminate`.
    public func terminate(pid: Int32, device: String) -> Self {
        operation(["device", "process", "terminate", "--device", device, "--pid", String(pid)])
    }

    // MARK: - Capture and simulation

    /// `device capture screenshot`.
    public func screenshot(device: String, destination: String) -> Self {
        operation(["device", "capture", "screenshot", "--device", device, "--destination", destination])
    }

    /// `device capture screen-record`; runs until the process is interrupted.
    public func screenRecord(device: String, destination: String) -> Self {
        operation(["device", "capture", "screen-record", "--device", device, "--destination", destination])
    }

    /// `device simulate location coordinate`.
    public func simulateLocation(latitude: Double, longitude: Double, device: String) -> Self {
        operation([
            "device", "simulate", "location", "coordinate", "--device", device,
            "--latitude", String(latitude), "--longitude", String(longitude),
        ])
    }

    /// `device simulate location clear`.
    public func clearSimulatedLocation(device: String) -> Self {
        operation(["device", "simulate", "location", "clear", "--device", device])
    }

    /// `device settings appearance`.
    public func appearance(_ mode: DeviceCtlAppearance, device: String) -> Self {
        operation(["device", "settings", "appearance", "--device", device, "--mode", mode.rawValue])
    }

    /// Any other `devicectl` subcommand.
    public func custom(_ arguments: [String]) -> Self {
        operation(arguments)
    }

    /// Builds the raw `xcrun devicectl` command.
    public func command() -> Command {
        var built = spec
        built.arguments += optionalOption("--json-output", jsonOutput)
        built.arguments += timeoutSeconds.map { ["--timeout", String($0)] } ?? []
        built.arguments += flag("--quiet", quiet)
        built.arguments += trailing
        return built.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) {
            $0.spec.arguments = values
            $0.trailing = []
        }
    }

    static func jsonObject(_ values: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
            let text = String(bytes: data, encoding: .utf8)
        else { return "{}" }
        return text
    }
}

/// Appearance modes accepted by `devicectl device settings appearance`.
public enum DeviceCtlAppearance: String, Sendable, CaseIterable {
    case light
    case dark
}
