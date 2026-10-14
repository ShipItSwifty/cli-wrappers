import Foundation
import SwiftyShell
import WrapperSupport

/// How a project's locally installed JavaScript CLI is invoked.
public enum JSPackageRunner: Sendable, Equatable {
    /// `npx <cli>`.
    case npx
    /// `yarn <cli>`.
    case yarn
    /// `pnpm exec <cli>`.
    case pnpm
    /// `bunx <cli>`.
    case bun

    var executable: String {
        switch self {
        case .npx: "npx"
        case .yarn: "yarn"
        case .pnpm: "pnpm"
        case .bun: "bunx"
        }
    }

    var prefix: [String] {
        self == .pnpm ? ["exec"] : []
    }
}

/// A typed wrapper for the React Native community CLI (`react-native`), run through the project's
/// package runner.
///
/// ```swift
/// try await ReactNative(context: shell).runIOS(simulator: "iPhone 16", mode: "Debug").run()
/// let metro = try await ReactNative(context: shell).start(port: 8081).spawn()
/// ```
public struct ReactNative: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), runner: JSPackageRunner = .npx) {
        self.spec = CommandSpec(executable: runner.executable, prefix: runner.prefix + ["react-native"], context: context)
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

    // MARK: - Build

    /// `react-native build-ios --mode <mode>`.
    public func buildIOS(mode: String = "Release", scheme: String? = nil) -> Self {
        operation(["build-ios", "--mode", mode] + optionalOption("--scheme", scheme))
    }

    /// `react-native build-android --mode=<mode>`.
    public func buildAndroid(mode: String = "release", task: String? = nil) -> Self {
        operation(["build-android", "--mode=\(mode)"] + optionalOption("--tasks", task))
    }

    /// `react-native bundle`: writes the JS bundle and assets for an offline build.
    public func bundle(
        platform: String,
        entryFile: String = "index.js",
        bundleOutput: String,
        assetsDestination: String? = nil,
        dev: Bool = false,
        minify: Bool? = nil
    ) -> Self {
        var values = [
            "bundle", "--platform", platform, "--entry-file", entryFile, "--bundle-output", bundleOutput,
            "--dev", String(dev),
        ]
        values += optionalOption("--assets-dest", assetsDestination)
        if let minify {
            values += ["--minify", String(minify)]
        }
        return operation(values)
    }

    // MARK: - Run

    /// `react-native run-ios`: builds, installs, and launches on a simulator or device.
    public func runIOS(
        simulator: String? = nil,
        udid: String? = nil,
        mode: String = "Debug",
        scheme: String? = nil,
        startPackager: Bool = true
    ) -> Self {
        operation(
            ["run-ios", "--mode", mode] + optionalOption("--simulator", simulator) + optionalOption("--udid", udid)
                + optionalOption("--scheme", scheme) + flag("--no-packager", !startPackager)
        )
    }

    /// `react-native run-android`: builds, installs, and launches on an emulator or device.
    public func runAndroid(
        deviceID: String? = nil,
        mode: String = "debug",
        applicationID: String? = nil,
        startPackager: Bool = true
    ) -> Self {
        operation(
            ["run-android", "--mode", mode] + optionalOption("--device", deviceID)
                + optionalOption("--appId", applicationID) + flag("--no-packager", !startPackager)
        )
    }

    /// `react-native start`: the Metro dev server. Long-lived, so `spawn` it.
    public func start(port: Int? = nil, resetCache: Bool = false) -> Self {
        operation(["start"] + optionalOption("--port", port.map(String.init)) + flag("--reset-cache", resetCache))
    }

    // MARK: - Inspection

    /// `react-native config`: JSON describing native projects and dependencies.
    public func config() -> Self {
        operation(["config"])
    }

    /// `react-native doctor`.
    public func doctor() -> Self {
        operation(["doctor"])
    }

    /// Any other `react-native` subcommand.
    public func custom(_ arguments: [String]) -> Self {
        operation(arguments)
    }

    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
