import Foundation
import WrapperSupport

// App installation and `device process`: launching, signalling, and watching processes.
extension DeviceCtl {
    // MARK: - Install

    /// `device install app`: installs an `.app` bundle. The JSON result carries the installed app's
    /// `launchServicesIdentifier`, which ``DeviceCtlLaunchOptions/launchPersistentIdentifier`` accepts.
    ///
    /// **Mutating**.
    public func install(appPath: String, device: String, columns: DeviceCtlColumnOptions = .init()) -> Self {
        modified(deviceOperation(["device", "install", "app"], device: device, columns.arguments)) { $0.trailing = [appPath] }
    }

    /// `device uninstall app`.
    ///
    /// **Mutating**.
    public func uninstall(bundleID: String, device: String) -> Self {
        modified(deviceOperation(["device", "uninstall", "app"], device: device)) { $0.trailing = [bundleID] }
    }

    // MARK: - Launch

    /// `device process launch`.
    ///
    /// App arguments follow a `--` so devicectl does not claim ones such as `-v`. To set environment
    /// variables from the calling environment instead, prefix them with `DEVICECTL_CHILD_`.
    ///
    /// - Parameters:
    ///   - bundleID: The bundle identifier of, or path to, the remote application.
    ///   - terminateExisting: Terminate a running instance first.
    ///   - console: Attach to the app's stdout and wait for it to exit. devicectl rejects
    ///     `--json-output -` with this; pass a file path.
    ///   - startStopped: Launch suspended, waiting for a debugger.
    ///   - environment: Encoded as the JSON object `--environment-variables` expects.
    ///   - payloadURL: A URL for the app to open during launch.
    ///   - options: User, working directory, architecture, activation, display, and persistent identifier.
    ///   - arguments: Passed to the app after its bundle identifier.
    ///
    /// **Mutating**.
    public func launch(
        bundleID: String,
        device: String,
        terminateExisting: Bool = false,
        console: Bool = false,
        startStopped: Bool = false,
        environment: [String: String] = [:],
        payloadURL: String? = nil,
        options: DeviceCtlLaunchOptions = .init(),
        arguments: [String] = []
    ) -> Self {
        var values = options.arguments
        values += flag("--terminate-existing", terminateExisting)
        values += flag("--console", console)
        values += flag("--start-stopped", startStopped)
        if !environment.isEmpty {
            values += ["--environment-variables", Self.jsonObject(environment)]
        }
        values += optionalOption("--payload-url", payloadURL)
        return modified(deviceOperation(["device", "process", "launch"], device: device, values)) {
            $0.trailing = [bundleID] + arguments
            $0.terminatesOptions = !arguments.isEmpty
        }
    }

    /// `device process openURL`: opens `url` in the app registered for it.
    ///
    /// **Mutating**.
    public func openURL(_ url: String, device: String, options: DeviceCtlOpenURLOptions = .init()) -> Self {
        modified(deviceOperation(["device", "process", "openURL"], device: device, options.arguments)) { $0.trailing = [url] }
    }

    // MARK: - Process control

    /// `device process signal`.
    ///
    /// **Mutating**.
    public func signal(_ signal: String = "SIGTERM", pid: Int32, device: String) -> Self {
        deviceOperation(["device", "process", "signal"], device: device, ["--pid", String(pid), "--signal", signal])
    }

    /// `device process terminate`. `kill` uses SIGKILL, which the process cannot catch, instead of SIGTERM.
    ///
    /// **Mutating**.
    public func terminate(pid: Int32, device: String, kill: Bool = false) -> Self {
        deviceOperation(["device", "process", "terminate"], device: device, ["--pid", String(pid)] + flag("--kill", kill))
    }

    /// `device process suspend`.
    ///
    /// **Mutating**.
    public func suspend(pid: Int32, device: String) -> Self {
        deviceOperation(["device", "process", "suspend"], device: device, ["--pid", String(pid)])
    }

    /// `device process resume`.
    ///
    /// **Mutating**.
    public func resume(pid: Int32, device: String) -> Self {
        deviceOperation(["device", "process", "resume"], device: device, ["--pid", String(pid)])
    }

    /// `device process sendMemoryWarning`.
    ///
    /// **Mutating**.
    public func sendMemoryWarning(pid: Int32, device: String) -> Self {
        deviceOperation(["device", "process", "sendMemoryWarning"], device: device, ["--pid", String(pid)])
    }

    /// `device process awaitTermination`: blocks until the process exits and reports its exit status.
    public func awaitTermination(pid: Int32, device: String) -> Self {
        deviceOperation(["device", "process", "awaitTermination"], device: device, ["--pid", String(pid)])
    }
}
