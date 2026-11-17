import Foundation
import SwiftyShell

/// A typed wrapper for `xcrun simctl` commands.
public struct Simctl: RunnableCommandFamily {
    private let state: State

    /// The shell context used when running this command family.
    public var context: ShellContext { state.xcrun.context }

    /// Creates a `simctl` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The `xcrun` executable, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcrun") {
        self.state = State(xcrun: Xcrun(context: context, executablePath: executablePath))
    }

    internal init(
        xcrun: Xcrun,
        operation: SimctlCommand? = nil,
        trailingArguments: [String] = []
    ) {
        self.state = State(
            xcrun: xcrun,
            operation: operation,
            trailingArguments: trailingArguments
        )
    }

    private init(state: State) {
        self.state = state
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(
        _ update: (ToolConfiguration) -> ToolConfiguration
    ) -> Self {
        copy(xcrun: state.xcrun.updatingConfiguration(update))
    }

    /// Redirects stdout for the built `simctl` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        copy(xcrun: state.xcrun.settingStdoutDestination(destination))
    }

    /// Redirects stderr for the built `simctl` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        copy(xcrun: state.xcrun.settingStderrDestination(destination))
    }

    /// Replaces the current typed `simctl` operation.
    public func command(_ value: SimctlCommand) -> Self {
        copy(operation: value)
    }

    /// Uses a custom `simctl` subcommand and arguments.
    public func custom(_ subcommand: String, arguments: [String] = []) -> Self {
        command(.custom(subcommand, arguments: arguments))
    }

    /// Appends a trailing argument after the typed `simctl` operation.
    public func arg(_ value: String) -> Self {
        copy(trailingArguments: state.trailingArguments + [value])
    }

    /// Appends multiple trailing arguments after the typed `simctl` operation.
    public func args(_ values: [String]) -> Self {
        copy(trailingArguments: state.trailingArguments + values)
    }

    /// Uses the `simctl list` subcommand.
    public func list(
        _ target: SimctlListTarget? = nil,
        json: Bool = false,
        searchTerm: String? = nil
    ) -> Self {
        command(.list(target, json: json, searchTerm: searchTerm))
    }

    /// Uses the `simctl help` subcommand.
    public func help(_ subject: String? = nil) -> Self {
        command(.help(subject))
    }

    /// **Mutating**: Uses the `simctl boot` subcommand.
    public func boot(_ device: String) -> Self {
        command(.boot(device))
    }

    /// Uses the `simctl bootstatus` subcommand.
    ///
    /// - Parameter boot: Pass `-b` to boot the device first if needed.
    public func bootStatus(_ device: String, boot: Bool = false) -> Self {
        command(.bootStatus(device, boot: boot))
    }

    /// **Mutating**: Uses the `simctl shutdown` subcommand.
    public func shutdown(_ devices: [String]) -> Self {
        command(.shutdown(devices))
    }

    /// **Mutating**: Uses the `simctl erase` subcommand.
    public func erase(_ devices: [String]) -> Self {
        command(.erase(devices))
    }

    /// **Mutating**: Uses the `simctl create` subcommand.
    public func create(name: String, deviceType: String, runtime: String) -> Self {
        command(.create(name: name, deviceType: deviceType, runtime: runtime))
    }

    /// **Mutating**: Uses the `simctl clone` subcommand.
    public func clone(_ device: String, to name: String) -> Self {
        command(.clone(device, to: name))
    }

    /// **Mutating**: Uses the `simctl delete` subcommand.
    public func delete(_ devices: [String]) -> Self {
        command(.delete(devices))
    }

    /// **Mutating**: Uses the `simctl rename` subcommand.
    public func rename(_ device: String, to name: String) -> Self {
        command(.rename(device, to: name))
    }

    /// **Mutating**: Uses the `simctl pair` subcommand.
    public func pair(_ watch: String, with phone: String) -> Self {
        command(.pair(watch, with: phone))
    }

    /// **Mutating**: Uses the `simctl unpair` subcommand.
    public func unpair(_ device: String) -> Self {
        command(.unpair(device))
    }

    /// **Mutating**: Uses the `simctl install` subcommand.
    public func install(_ device: String, appAt path: String) -> Self {
        command(.install(device, appAt: path))
    }

    /// **Mutating**: Uses the `simctl uninstall` subcommand.
    public func uninstall(_ device: String, bundleIdentifier: String) -> Self {
        command(.uninstall(device, bundleIdentifier: bundleIdentifier))
    }

    /// **Mutating**: Uses the `simctl launch` subcommand.
    ///
    /// - Parameters:
    ///   - arguments: Arguments passed to the app after the bundle identifier.
    ///   - environment: Variables for the launched app. `simctl` only forwards variables carrying
    ///     the `SIMCTL_CHILD_` prefix, so each `name` is rendered as `SIMCTL_CHILD_<name>` on the command.
    ///   - terminateRunning: Relaunch an already-running app (`--terminate-running-process`).
    ///   - waitForDebugger: Start the app suspended (`--wait-for-debugger`).
    ///   - console: Attach the app's output to the command.
    public func launch(
        _ device: String,
        bundleIdentifier: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        terminateRunning: Bool = false,
        waitForDebugger: Bool = false,
        console: SimctlLaunchConsole? = nil
    ) -> Self {
        let launched = command(
            .launch(
                device,
                bundleIdentifier: bundleIdentifier,
                arguments: arguments,
                terminateRunning: terminateRunning,
                waitForDebugger: waitForDebugger,
                console: console
            ))
        guard !environment.isEmpty else { return launched }
        let prefixed = Dictionary(uniqueKeysWithValues: environment.map { ("SIMCTL_CHILD_\($0.key)", $0.value) })
        return launched.updatingConfiguration { $0.env(prefixed) }
    }

    /// **Mutating**: Uses the `simctl terminate` subcommand.
    public func terminate(_ device: String, bundleIdentifier: String) -> Self {
        command(.terminate(device, bundleIdentifier: bundleIdentifier))
    }

    /// Uses the `simctl spawn` subcommand.
    public func spawn(_ device: String, executable: String, arguments: [String] = []) -> Self {
        command(.spawn(device, executable: executable, arguments: arguments))
    }

    /// **Mutating**: Uses the `simctl openurl` subcommand.
    public func openURL(_ device: String, _ value: String) -> Self {
        command(.openURL(device, value))
    }

    /// Uses the `simctl get_app_container` subcommand.
    public func getAppContainer(
        _ device: String,
        bundleIdentifier: String,
        container: String? = nil
    ) -> Self {
        command(.getAppContainer(device, bundleIdentifier: bundleIdentifier, container: container))
    }

    /// Uses the `simctl getenv` subcommand.
    public func getenv(_ device: String, variable: String) -> Self {
        command(.getenv(device, variable: variable))
    }

    /// Uses the `simctl listapps` subcommand.
    public func listApps(_ device: String) -> Self {
        command(.listApps(device))
    }

    /// Uses the `simctl appinfo` subcommand.
    public func appInfo(_ device: String, bundleIdentifier: String) -> Self {
        command(.appInfo(device, bundleIdentifier: bundleIdentifier))
    }

    /// **Mutating**: Uses the `simctl addmedia` subcommand.
    public func addMedia(_ device: String, files: [String]) -> Self {
        command(.addMedia(device, files: files))
    }

    /// **Mutating**: Uses the `simctl pbcopy` subcommand.
    public func pbcopy(_ device: String) -> Self {
        command(.pbcopy(device))
    }

    /// Uses the `simctl pbpaste` subcommand.
    public func pbpaste(_ device: String) -> Self {
        command(.pbpaste(device))
    }

    /// Uses the `simctl io` subcommand.
    public func io(_ device: String, command name: String, arguments: [String] = []) -> Self {
        command(.io(device, command: name, arguments: arguments))
    }

    /// **Mutating**: Uses the `simctl privacy` subcommand.
    public func privacy(
        _ device: String,
        action: String,
        service: String,
        bundleIdentifier: String? = nil
    ) -> Self {
        command(.privacy(device, action: action, service: service, bundleIdentifier: bundleIdentifier))
    }

    /// **Mutating**: Uses the `simctl status_bar` subcommand.
    public func statusBar(_ device: String, arguments: [String]) -> Self {
        command(.statusBar(device, arguments: arguments))
    }

    /// Uses the `simctl ui` subcommand.
    public func ui(_ device: String, arguments: [String]) -> Self {
        command(.ui(device, arguments: arguments))
    }

    /// **Mutating**: Uses the `simctl push` subcommand.
    public func push(_ device: String, bundleIdentifier: String, payloadAt path: String) -> Self {
        command(.push(device, bundleIdentifier: bundleIdentifier, payloadAt: path))
    }

    /// **Mutating**: Uses the `simctl notify_post` subcommand.
    public func notifyPost(_ device: String, notification: String) -> Self {
        command(.notifyPost(device, notification: notification))
    }

    /// **Mutating**: Uses the `simctl location` subcommand.
    public func location(_ device: String, action: String, arguments: [String] = []) -> Self {
        command(.location(device, action: action, arguments: arguments))
    }

    /// **Mutating**: Uses the `simctl keychain` subcommand.
    public func keychain(_ device: String, arguments: [String]) -> Self {
        command(.keychain(device, arguments: arguments))
    }

    /// **Mutating**: Uses the `simctl icloud_sync` subcommand.
    public func icloudSync(_ device: String) -> Self {
        command(.icloudSync(device))
    }

    /// Uses the `simctl runtime` subcommand.
    public func runtime(arguments: [String]) -> Self {
        command(.runtime(arguments))
    }

    /// **Mutating**: Uses the `simctl upgrade` subcommand.
    public func upgrade(_ devices: [String]) -> Self {
        command(.upgrade(devices))
    }

    /// Uses the `simctl disk` subcommand.
    public func disk(arguments: [String]) -> Self {
        command(.disk(arguments))
    }

    /// Uses the `simctl diagnose` subcommand.
    public func diagnose(arguments: [String] = []) -> Self {
        command(.diagnose(arguments: arguments))
    }

    /// Builds the raw `xcrun simctl` command.
    public func command() -> Command {
        var xcrun = state.xcrun.tool("simctl")
        if let operation = state.operation {
            xcrun = xcrun.trailingArguments(operation.arguments)
        }
        if !state.trailingArguments.isEmpty {
            xcrun = xcrun.trailingArguments(state.trailingArguments)
        }
        return xcrun.command()
    }

    /// Builds the raw `xcrun simctl` command.
    public func buildCommand() -> Command {
        command()
    }

    private func copy(
        xcrun: Xcrun? = nil,
        operation: SimctlCommand?? = nil,
        trailingArguments: [String]? = nil
    ) -> Self {
        Self(
            state: State(
                xcrun: xcrun ?? state.xcrun,
                operation: operation ?? state.operation,
                trailingArguments: trailingArguments ?? state.trailingArguments
            ))
    }
}

private struct State: Sendable {
    let xcrun: Xcrun
    let operation: SimctlCommand?
    let trailingArguments: [String]

    init(
        xcrun: Xcrun,
        operation: SimctlCommand? = nil,
        trailingArguments: [String] = []
    ) {
        self.xcrun = xcrun
        self.operation = operation
        self.trailingArguments = trailingArguments
    }
}
