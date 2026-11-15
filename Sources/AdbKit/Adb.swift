import Foundation
import SwiftyShell
internal import WrapperSupport

/// A fluent wrapper for the Android Debug Bridge (`adb`) command.
///
/// Provides typed methods for common `adb` operations. All execution goes through
/// the injected `ShellContext`. Device targeting, daemon lifecycle, app management,
/// activity manager (`am`), package manager (`pm`), capture (`screencap`,
/// `screenrecord`), input events, port forwarding, and emulator control are all
/// modelled as fluent methods so consumers do not have to compose raw shell strings.
///
/// ## Usage
/// ```swift
/// // Install an APK on a specific device
/// try await Adb(context: context)
///     .serial("emulator-5554")
///     .install(apk: "./build/app-release.apk", replace: true)
///     .run()
///
/// // Launch an activity
/// try await Adb(context: context)
///     .serial("emulator-5554")
///     .amStartActivity(component: "com.example/.MainActivity", extras: ["arg": "hello"])
///     .run()
///
/// // List installed packages
/// let output = try await Adb(context: context).pmListPackages().run()
/// ```
public struct Adb: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext {
        spec.config.context
    }

    // MARK: - Init

    /// Creates an `Adb` command family bound to a shell context.
    ///
    /// The new client has no serial set and no subcommand selected. Chain a
    /// subcommand method (e.g. ``devices(long:)``, ``install(apk:replace:)``) before
    /// calling ``run()``.
    ///
    /// - Parameters:
    ///   - context: The shell context that supplies the executor, environment, and search paths
    ///     used at runtime.
    ///   - executablePath: Explicit `adb` path. When `nil`, uses
    ///     `$ANDROID_HOME/platform-tools/adb` (or `$ANDROID_SDK_ROOT/…`) from the shell context's
    ///     environment if it exists, and otherwise `adb` on `PATH`.
    public init(context: ShellContext = .init(), executablePath: String? = nil) {
        self.spec = CommandSpec(
            executable: executablePath ?? Self.resolveExecutable(environment: context.environment),
            context: context
        )
    }

    /// Resolves the SDK's `adb` binary from `ANDROID_HOME` / `ANDROID_SDK_ROOT`, falling back to
    /// `adb` on `PATH`.
    static func resolveExecutable(
        environment: [String: String],
        fileExists: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> String {
        AndroidSDK.executable(
            ["platform-tools/adb"],
            fallback: "adb",
            environment: environment,
            fileExists: fileExists
        )
    }

    // MARK: - RunnableCommandFamily

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `adb` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `adb` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Builds the raw `adb` command, prefixing `-s <serial>` when one is set.
    public func command() -> Command {
        spec.command()
    }

    // MARK: - Device targeting

    /// Targets the given device serial. Subsequent invocations of ``command()``
    /// prefix the resulting `adb` command with `-s <serial>`.
    ///
    /// Pass `nil` to target whichever single device is connected (no `-s` prefix).
    ///
    /// - Parameter value: The ADB serial of the target device, e.g.
    ///   `"emulator-5554"` or `"R5CT2074MZ"`. Passing `nil` clears any previously
    ///   set serial.
    public func serial(_ value: String?) -> Self {
        modified(self) {
            if let value, !value.isEmpty {
                $0.spec.globalArguments = ["-s", value]
            } else {
                $0.spec.globalArguments = []
            }
        }
    }

    // MARK: - Daemon lifecycle

    /// **Mutating**: `adb start-server` — Ensure the local adb daemon is running.
    public func startServer() -> Self {
        operation(["start-server"])
    }

    /// **Mutating**: `adb kill-server` — Stop the local adb daemon.
    public func killServer() -> Self {
        operation(["kill-server"])
    }

    // MARK: - Device discovery

    /// `adb devices [-l]` — List connected devices.
    ///
    /// - Parameter long: Pass `-l` to include the device transport id and product
    ///   metadata.
    public func devices(long: Bool = false) -> Self {
        operation(long ? ["devices", "-l"] : ["devices"])
    }

    /// `adb wait-for-device` — Block until a device is connected and available.
    public func waitForDevice() -> Self {
        operation(["wait-for-device"])
    }

    /// Uses explicit `adb` arguments for operations that are not yet modelled.
    ///
    /// Prefer the typed helpers on ``Adb`` when one fits. This method still routes
    /// through the `Adb` command family so device targeting, output redirection,
    /// and ``ShellContext`` injection remain consistent.
    ///
    /// - Parameter values: Arguments passed after the `adb` executable and any
    ///   configured `-s <serial>` prefix.
    public func rawArguments(_ values: [String]) -> Self {
        operation(values)
    }

    // MARK: - App lifecycle

    /// `adb install [-r] <apk>` — Install an APK on the connected device.
    ///
    /// - Parameters:
    ///   - apk: Path to the APK file.
    ///   - replace: Pass `-r` to replace an existing installation.
    public func install(apk: String, replace: Bool = false) -> Self {
        install(apk: apk, replace: replace, allowTestPackages: false, grantAllPermissions: false)
    }

    /// **Mutating**: `adb install [-r] [-t] [-g] <apk>` — Install an APK with explicit install options.
    ///
    /// - Parameters:
    ///   - apk: Path to the APK file.
    ///   - replace: Pass `-r` to replace an existing installation.
    ///   - allowTestPackages: Pass `-t` to allow `android:testOnly` APKs (e.g. debug or
    ///     instrumentation test APKs built by Android Studio).
    ///   - grantAllPermissions: Pass `-g` to grant every runtime permission listed in the manifest,
    ///     so UI tests do not stall on permission dialogs.
    public func install(apk: String, replace: Bool, allowTestPackages: Bool, grantAllPermissions: Bool) -> Self {
        var args = ["install"]
        if replace { args.append("-r") }
        if allowTestPackages { args.append("-t") }
        if grantAllPermissions { args.append("-g") }
        args.append(apk)
        return operation(args)
    }

    /// **Mutating**: `adb uninstall <package>` — Uninstall the given package.
    public func uninstall(package: String) -> Self {
        operation(["uninstall", package])
    }

    /// **Mutating**: `adb shell am force-stop <package>` — Terminate the given app on the device.
    public func amForceStop(package: String) -> Self {
        operation(["shell", "am", "force-stop", package])
    }

    /// `adb shell am start -n <component> [--es key value]...` — Launch an
    /// activity component with optional string extras.
    ///
    /// - Parameters:
    ///   - component: The `package/.Activity` component name to launch.
    ///   - extras: Optional string extras passed via repeated `--es key value`.
    ///     Useful for forwarding launch arguments to the app under test.
    public func amStartActivity(component: String, extras: [String: String] = [:]) -> Self {
        var args = ["shell", "am", "start", "-n", component]
        for (key, value) in extras.sorted(by: { $0.key < $1.key }) {
            args += ["--es", key, value]
        }
        return operation(args)
    }

    /// `adb shell am start -n <component> [--es arg value]...` — Launch an
    /// activity component with repeated launch argument extras.
    ///
    /// This is useful for test harnesses that forward argv-style values where
    /// order and duplicates matter.
    ///
    /// - Parameters:
    ///   - component: The `package/.Activity` component name to launch.
    ///   - arguments: Ordered values passed as repeated `--es arg <value>` extras.
    public func amStartActivity(component: String, arguments: [String]) -> Self {
        var args = ["shell", "am", "start", "-n", component]
        for argument in arguments {
            args += ["--es", "arg", argument]
        }
        return operation(args)
    }

    /// `adb shell am start -a android.intent.action.VIEW -d <url>` — Open a URL
    /// or deep link via the activity manager.
    ///
    /// - Parameter url: The URL to open. Callers should validate the URL scheme
    ///   against an allow-list before forwarding it; ADB sends the URL through
    ///   the device shell which will tokenise on whitespace and metacharacters.
    public func amStartViewURL(_ url: String) -> Self {
        operation([
            "shell", "am", "start",
            "-a", "android.intent.action.VIEW",
            "-d", url,
        ])
    }

    // MARK: - Package manager

    /// `adb shell getprop <property>` — Read a system property, e.g. `sys.boot_completed`
    /// (`"1"` once an emulator has finished booting) or `ro.build.version.sdk`.
    public func getprop(_ property: String) -> Self {
        operation(["shell", "getprop", property])
    }

    /// `adb shell pm list packages` — List installed packages on the device.
    public func pmListPackages() -> Self {
        operation(["shell", "pm", "list", "packages"])
    }

    /// **Mutating**: `adb shell pm grant <package> <permission>` — Grant a runtime permission.
    public func pmGrantPermission(package: String, permission: String) -> Self {
        operation(["shell", "pm", "grant", package, permission])
    }

    /// **Mutating**: `adb shell pm revoke <package> <permission>` — Revoke a runtime permission.
    public func pmRevokePermission(package: String, permission: String) -> Self {
        operation(["shell", "pm", "revoke", package, permission])
    }

    /// `adb shell cmd package resolve-activity --brief <package>` — Resolve the
    /// launchable activity component for a package.
    public func resolveLaunchableActivity(package: String) -> Self {
        operation([
            "shell", "cmd", "package", "resolve-activity", "--brief", package,
        ])
    }

    // MARK: - Capture

    /// `adb shell screencap -p <remote-path>` — Capture a PNG screenshot to a
    /// path on the device.
    public func screencap(remotePath: String) -> Self {
        operation(["shell", "screencap", "-p", remotePath])
    }

    /// `adb shell screenrecord <remote-path>` — Start recording the device
    /// display to an MP4 file. The command runs until interrupted (`SIGINT`) or
    /// the recording reaches the device-imposed maximum duration.
    public func screenrecord(remotePath: String) -> Self {
        operation(["shell", "screenrecord", remotePath])
    }

    /// `adb shell pkill -INT <process>` — Send `SIGINT` to a process on the
    /// device by name.
    public func shellPkill(signal: String = "INT", process: String) -> Self {
        operation(["shell", "pkill", "-\(signal)", process])
    }

    // MARK: - Input

    /// `adb shell input keyevent <keycode>` — Synthesize a hardware key event.
    public func inputKeyevent(_ keycode: String) -> Self {
        operation(["shell", "input", "keyevent", keycode])
    }

    // MARK: - Display configuration

    /// **Mutating**: `adb shell cmd uimode night <yes|no|auto>` — Set the device's dark/light
    /// appearance mode.
    public func cmdUimodeNight(_ value: UimodeNight) -> Self {
        operation(["shell", "cmd", "uimode", "night", value.rawValue])
    }

    /// Values accepted by ``cmdUimodeNight(_:)``.
    public enum UimodeNight: String, Sendable, Equatable, Hashable {
        /// Dark mode (`yes`).
        case yes
        /// Light mode (`no`).
        case no
        /// System auto (`auto`).
        case auto
    }

    /// `adb shell pm path <package>` — Reports the installed APK path.
    public func pmPath(package: String) -> Self {
        operation(["shell", "pm", "path", package])
    }

    // MARK: - Port forwarding

    /// `adb forward --list` — Lists every device's forwarded ports.
    public func listForwards() -> Self {
        operation(["forward", "--list"])
    }

    /// **Mutating**: `adb forward tcp:<local> tcp:<remote>` — Forward a host TCP port to the
    /// device.
    public func forwardTCP(localPort: Int, remotePort: Int) -> Self {
        operation(["forward", "tcp:\(localPort)", "tcp:\(remotePort)"])
    }

    /// **Mutating**: `adb forward --remove tcp:<local>` — Remove a previously installed TCP
    /// port forward.
    public func removeForwardTCP(localPort: Int) -> Self {
        operation(["forward", "--remove", "tcp:\(localPort)"])
    }

    // MARK: - File transfer

    /// **Mutating**: `adb push <local> <remote>` — Push a local file to the device.
    public func push(local: String, remote: String) -> Self {
        operation(["push", local, remote])
    }

    /// `adb pull <remote> <local>` — Pull a file from the device.
    public func pull(remote: String, local: String) -> Self {
        operation(["pull", remote, local])
    }

    // MARK: - Shell

    /// `adb shell <command>` — Execute a free-form shell command on the device.
    ///
    /// Prefer the typed helpers (`amStartActivity`, `pmGrantPermission`, etc.)
    /// when one fits; this method exists as an escape hatch for commands that
    /// are not yet modelled. The argument is passed verbatim to the on-device
    /// shell, which will tokenise on whitespace and metacharacters.
    public func shell(_ command: String) -> Self {
        operation(["shell", command])
    }

    // MARK: - Emulator control

    /// **Mutating**: `adb emu kill` — Shut down the connected emulator.
    public func emuKill() -> Self {
        operation(["emu", "kill"])
    }

    /// `adb emu geo fix <longitude> <latitude>` — Set the simulated GPS
    /// location on the connected emulator.
    ///
    /// > Important: The emulator console expects **longitude first**, then
    /// > latitude — the same order this method accepts.
    public func emuGeoFix(longitude: Double, latitude: Double) -> Self {
        operation(["emu", "geo", "fix", String(longitude), String(latitude)])
    }

    // MARK: - Logcat

    /// `adb logcat [-c] [-d] [filters]` — Read or clear logcat output.
    ///
    /// - Parameters:
    ///   - clear: Pass `-c` to clear the buffer and exit. Clearing mutates device state.
    ///   - dump: Pass `-d` to dump the current buffer and exit instead of streaming.
    ///   - filters: Optional filter specifications (e.g. `["*:E"]` for errors only).
    public func logcat(clear: Bool = false, dump: Bool = false, filters: [String] = []) -> Self {
        operation(["logcat"] + flag("-c", clear) + flag("-d", dump) + filters)
    }

    // MARK: - Server and device state

    /// `adb version` — Report the adb client version.
    public func version() -> Self {
        operation(["version"])
    }

    /// **Mutating**: `adb reconnect` — Drop and re-establish the connection to the device.
    public func reconnect() -> Self {
        operation(["reconnect"])
    }

    /// `adb emu avd name` — Report the AVD name of the connected emulator.
    public func emuAVDName() -> Self {
        operation(["emu", "avd", "name"])
    }

    // MARK: - Additional package and file operations

    /// **Mutating**: `adb shell pm clear <package>` — Delete a package's data and cache.
    public func pmClear(package: String) -> Self {
        operation(["shell", "pm", "clear", package])
    }

    /// **Mutating**: `adb shell rm [-f] <path>` — Remove a file on the device.
    ///
    /// - Parameters:
    ///   - remotePath: Path on the device.
    ///   - force: Pass `-f` to ignore a missing file.
    public func removeFile(remotePath: String, force: Bool = false) -> Self {
        operation(["shell", "rm"] + flag("-f", force) + [remotePath])
    }

    /// `adb shell cmd package resolve-activity --brief [-a <action>] [-c <category>] <package>` —
    /// Resolve the activity an intent would launch.
    ///
    /// - Parameters:
    ///   - package: Package (or component) to resolve against.
    ///   - action: Intent action, for example `android.intent.action.MAIN`.
    ///   - category: Intent category, for example `android.intent.category.LAUNCHER`.
    public func resolveActivity(package: String, action: String? = nil, category: String? = nil) -> Self {
        operation(
            ["shell", "cmd", "package", "resolve-activity", "--brief"] + optionalOption("-a", action)
                + optionalOption("-c", category) + [package]
        )
    }

    /// **Mutating**: `adb install-multiple [-r] [-t] [-g] <apk>...` — Install split APKs as one package.
    public func installMultiple(
        apks: [String],
        replace: Bool = false,
        allowTestPackages: Bool = false,
        grantAllPermissions: Bool = false
    ) -> Self {
        operation(
            ["install-multiple"] + flag("-r", replace) + flag("-t", allowTestPackages) + flag("-g", grantAllPermissions) + apks
        )
    }

    // MARK: - Activity manager

    /// **Mutating**: `adb shell am start [-W] [-S] [--activity-clear-top] [--user <id>] -n <component> [extras]`.
    ///
    /// Typed extras keep their order, so repeated keys and mixed types are expressible.
    ///
    /// - Parameters:
    ///   - component: The `package/.Activity` component name to launch.
    ///   - wait: Pass `-W` to block until the launch completes.
    ///   - forceStop: Pass `-S` to force-stop the target app before launching.
    ///   - clearTop: Pass `--activity-clear-top` to finish activities above the target in its task.
    ///   - user: Pass `--user <id>` to launch for a specific user.
    ///   - typedExtras: Intent extras rendered in order.
    public func amStartActivity(
        component: String,
        wait: Bool = false,
        forceStop: Bool = false,
        clearTop: Bool = false,
        user: Int? = nil,
        typedExtras: [AdbIntentExtra]
    ) -> Self {
        operation(
            ["shell", "am", "start"] + flag("-W", wait) + flag("-S", forceStop) + flag("--activity-clear-top", clearTop)
                + optionalOption("--user", user.map(String.init)) + ["-n", component] + typedExtras.flatMap(\.arguments)
        )
    }

    /// **Mutating**: `adb shell am instrument -w [-r] [-e <key> <value>]... <runner>` — Run instrumentation tests.
    ///
    /// - Parameters:
    ///   - runner: The `package/runner` instrumentation component.
    ///   - wait: Pass `-w` to wait for the run to finish (the default, as `adb` would otherwise return at once).
    ///   - raw: Pass `-r` for raw, machine-readable output.
    ///   - arguments: Instrumentation arguments passed as `-e key value`, sorted by key.
    public func amInstrument(
        runner: String,
        wait: Bool = true,
        raw: Bool = false,
        arguments: [String: String] = [:]
    ) -> Self {
        operation(
            ["shell", "am", "instrument"] + flag("-w", wait) + flag("-r", raw)
                + arguments.sorted(by: { $0.key < $1.key }).flatMap { ["-e", $0.key, $0.value] } + [runner]
        )
    }

    // MARK: - Reverse port forwarding

    /// **Mutating**: `adb reverse tcp:<remote> tcp:<local>` — Expose a host TCP port to the device.
    public func reverseTCP(remotePort: Int, localPort: Int) -> Self {
        operation(["reverse", "tcp:\(remotePort)", "tcp:\(localPort)"])
    }

    /// **Mutating**: `adb reverse --remove tcp:<remote>` — Remove a reverse port mapping.
    public func removeReverse(remotePort: Int) -> Self {
        operation(["reverse", "--remove", "tcp:\(remotePort)"])
    }

    // MARK: - Capture and input

    /// `adb exec-out screencap -p` — Stream a PNG screenshot to stdout without a device-side file.
    public func execOutScreencap() -> Self {
        operation(["exec-out", "screencap", "-p"])
    }

    /// **Mutating**: `adb shell input tap <x> <y>`.
    public func inputTap(x: Int, y: Int) -> Self {
        operation(["shell", "input", "tap", String(x), String(y)])
    }

    /// **Mutating**: `adb shell input text <text>`.
    ///
    /// The text is passed verbatim. The device shell splits on whitespace, so encode spaces as
    /// `%s` before calling.
    public func inputText(_ text: String) -> Self {
        operation(["shell", "input", "text", text])
    }

    /// **Mutating**: `adb shell input swipe <x1> <y1> <x2> <y2> [<duration>]`.
    public func inputSwipe(
        fromX: Int,
        fromY: Int,
        toX: Int,
        toY: Int,
        durationMilliseconds: Int? = nil
    ) -> Self {
        operation(
            ["shell", "input", "swipe", String(fromX), String(fromY), String(toX), String(toY)]
                + (durationMilliseconds.map { [String($0)] } ?? [])
        )
    }

    // MARK: - Private

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}

/// A typed intent extra for ``Adb/amStartActivity(component:wait:forceStop:clearTop:user:typedExtras:)``.
public enum AdbIntentExtra: Sendable, Equatable, Hashable {
    /// `--es <key> <value>`.
    case string(String, String)
    /// `--ez <key> true|false`.
    case bool(String, Bool)
    /// `--ei <key> <value>`.
    case int(String, Int)
    /// `--el <key> <value>`.
    case long(String, Int64)
    /// `--ef <key> <value>`.
    case float(String, Double)

    var arguments: [String] {
        switch self {
        case .string(let key, let value): ["--es", key, value]
        case .bool(let key, let value): ["--ez", key, value ? "true" : "false"]
        case .int(let key, let value): ["--ei", key, String(value)]
        case .long(let key, let value): ["--el", key, String(value)]
        case .float(let key, let value): ["--ef", key, String(value)]
        }
    }
}
