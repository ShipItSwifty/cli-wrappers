import Foundation
import SwiftyShell
internal import WrapperSupport

/// A fluent wrapper for the Android `emulator` command-line tool.
///
/// Used to start and manage Android Virtual Devices (AVDs) in CI environments.
///
/// ## Usage
/// ```swift
/// // Start emulator headless (CI mode)
/// let emulator = Emulator(context: context.shell).start(avd: "test_device", headless: true)
/// let output = try await emulator.run()
///
/// // Wait for boot (separate adb call)
/// let booted = try await Adb(context: context.shell)
///     .shell("getprop sys.boot_completed")
///     .run()
/// ```
public struct Emulator: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    // MARK: - Init

    /// Creates an `Emulator` command family bound to a shell context.
    ///
    /// - Parameters:
    ///   - context: Shell execution context.
    ///   - executablePath: Explicit `emulator` path. When `nil`, uses
    ///     `$ANDROID_HOME/emulator/emulator` (or `$ANDROID_SDK_ROOT/…`) from the shell context's
    ///     environment if it exists — the SDK does not put `emulator/` on `PATH` — and otherwise
    ///     falls back to `emulator` on `PATH`.
    public init(context: ShellContext = .init(), executablePath: String? = nil) {
        self.spec = CommandSpec(
            executable: executablePath ?? Self.resolveExecutable(environment: context.environment),
            context: context
        )
    }

    /// Resolves the SDK's `emulator` binary from `ANDROID_HOME` / `ANDROID_SDK_ROOT`, falling back
    /// to `emulator` on `PATH`.
    static func resolveExecutable(
        environment: [String: String],
        fileExists: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> String {
        AndroidSDK.executable(["emulator/emulator"], fallback: "emulator", environment: environment, fileExists: fileExists)
    }

    // MARK: - RunnableCommandFamily

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Builds the raw `emulator` command.
    public func command() -> Command {
        spec.command()
    }

    // MARK: - Subcommands

    /// **Mutating**: `emulator -avd <name> [options]` — Start an AVD.
    ///
    /// - Parameters:
    ///   - avd: AVD name (as returned by ``list()`` or `avdmanager list avd`).
    ///   - headless: Pass `-no-window -no-audio -no-boot-anim` for headless CI operation. Required
    ///     on machines without a display, where a windowed emulator exits immediately.
    ///   - gpu: GPU acceleration mode (e.g. `"swiftshader_indirect"` for CI without GPU).
    ///   - snapshot: Quick-boot snapshot handling; `.disabled` cold boots and never saves, so every
    ///     run starts from the same device state.
    ///   - wipeData: Pass `-wipe-data` to reset user data to factory state.
    ///   - readOnly: Pass `-read-only` so several emulators can run from the same AVD concurrently.
    ///   - port: Pass `-port <n>` to pin the console port, which fixes the serial to
    ///     `emulator-<n>` (must be an even number between 5554 and 5682).
    public func start(
        avd: String,
        headless: Bool = false,
        gpu: String? = nil,
        snapshot: EmulatorSnapshot = .loadAndSave,
        wipeData: Bool = false,
        readOnly: Bool = false,
        port: Int? = nil,
        additionalArguments: [String] = []
    ) -> Self {
        var args = ["-avd", avd]
        if headless {
            args += ["-no-window", "-no-audio", "-no-boot-anim"]
        }
        if let gpu {
            args += ["-gpu", gpu]
        }
        args += snapshot.arguments
        if wipeData { args.append("-wipe-data") }
        if readOnly { args.append("-read-only") }
        if let port { args += ["-port", String(port)] }
        return operation(args + additionalArguments)
    }

    /// `emulator -list-avds` — List all available AVDs.
    public func list() -> Self {
        operation(["-list-avds"])
    }

    // MARK: - Private

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}

/// How the emulator uses its quick-boot snapshot.
public enum EmulatorSnapshot: Sendable, Equatable {
    /// Load the snapshot at boot and save it on exit (the emulator's default).
    case loadAndSave
    /// Load the snapshot for a fast boot but never save, so state does not accumulate (`-no-snapshot-save`).
    case loadOnly
    /// Cold boot, but save on exit (`-no-snapshot-load`).
    case saveOnly
    /// Cold boot and never save (`-no-snapshot`).
    case disabled

    public var arguments: [String] {
        switch self {
        case .loadAndSave: []
        case .loadOnly: ["-no-snapshot-save"]
        case .saveOnly: ["-no-snapshot-load"]
        case .disabled: ["-no-snapshot"]
        }
    }
}
