import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for the `flutter` CLI: dependencies, builds for devices and simulators,
/// install/run, unit and integration tests, and inventory.
///
/// ```swift
/// try await Flutter(context: shell).pubGet().run()
/// let app = try await Flutter(context: shell).build(.ios, mode: .debug, simulator: true).run()
/// let events = try await Flutter(context: shell).testMachine().run()   // newline-delimited JSON
/// ```
public struct Flutter: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// - Parameter executablePath: `flutter`, or e.g. `fvm flutter` split as `fvm` with a `flutter` prefix.
    public init(context: ShellContext = .init(), executablePath: String = "flutter", prefix: [String] = []) {
        self.spec = CommandSpec(executable: executablePath, prefix: prefix, context: context)
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

    // MARK: - Project

    /// `flutter pub get`.
    public func pubGet(offline: Bool = false, enforceLockfile: Bool = false) -> Self {
        operation(["pub", "get"] + flag("--offline", offline) + flag("--enforce-lockfile", enforceLockfile))
    }

    /// `flutter clean`.
    public func clean() -> Self {
        operation(["clean"])
    }

    /// `flutter analyze` (static analysis).
    public func analyze() -> Self {
        operation(["analyze"])
    }

    // MARK: - Build

    /// `flutter build <target>`.
    ///
    /// - Parameters:
    ///   - simulator: Build for the iOS Simulator (`--simulator`, `.ios` only).
    ///   - codesign: `false` passes `--no-codesign` (iOS); `nil` leaves Flutter's default.
    ///   - entryPoint: Dart entry point (`--target`), e.g. `lib/main_prod.dart`.
    ///   - buildName / buildNumber: Override the `pubspec.yaml` version.
    public func build(
        _ target: FlutterBuildTarget,
        mode: FlutterBuildMode = .release,
        simulator: Bool = false,
        codesign: Bool? = nil,
        flavor: String? = nil,
        dartDefines: [String: String] = [:],
        entryPoint: String? = nil,
        buildName: String? = nil,
        buildNumber: String? = nil,
        exportOptionsPlist: String? = nil
    ) -> Self {
        var values = ["build", target.rawValue] + flag("--simulator", simulator) + [mode.flag]
        if codesign == false {
            values.append("--no-codesign")
        }
        values += optionalOption("--flavor", flavor)
        values += dartDefines.sorted { $0.key < $1.key }.map { "--dart-define=\($0.key)=\($0.value)" }
        values += optionalOption("--target", entryPoint)
        values += optionalFlag("--build-name", buildName) + optionalFlag("--build-number", buildNumber)
        values += optionalOption("--export-options-plist", exportOptionsPlist)
        return operation(values)
    }

    /// `flutter build ios --release --no-codesign`: a compile check without an IPA.
    public func buildIOS(flavor: String? = nil, dartDefines: [String: String] = [:], target: String? = nil) -> Self {
        build(.ios, codesign: false, flavor: flavor, dartDefines: dartDefines, entryPoint: target)
    }

    /// `flutter build ipa --release`: produces `build/ios/ipa/*.ipa`.
    public func buildIPA(flavor: String? = nil, dartDefines: [String: String] = [:], target: String? = nil) -> Self {
        build(.ipa, flavor: flavor, dartDefines: dartDefines, entryPoint: target)
    }

    /// `flutter build appbundle --release`: produces `build/app/outputs/bundle/release/app-release.aab`.
    public func buildAppBundle(flavor: String? = nil, dartDefines: [String: String] = [:], target: String? = nil) -> Self {
        build(.appbundle, flavor: flavor, dartDefines: dartDefines, entryPoint: target)
    }

    /// `flutter build apk --release`: produces `build/app/outputs/flutter-apk/app-release.apk`.
    public func buildAPK(flavor: String? = nil, dartDefines: [String: String] = [:], target: String? = nil) -> Self {
        build(.apk, flavor: flavor, dartDefines: dartDefines, entryPoint: target)
    }

    // MARK: - Devices, install, run

    /// `flutter devices`; `machine` emits JSON.
    public func devices(machine: Bool = true) -> Self {
        operation(["devices"] + flag("--machine", machine))
    }

    /// `flutter emulators`.
    public func emulators() -> Self {
        operation(["emulators"])
    }

    /// `flutter install -d <device>`, optionally from a prebuilt binary.
    public func install(device: String, mode: FlutterBuildMode = .release, applicationBinary: String? = nil) -> Self {
        operation(["install", "-d", device, mode.flag] + optionalFlag("--use-application-binary", applicationBinary))
    }

    /// `flutter run -d <device>`. Named `runApp` because `run()` executes the command; long-lived, so `spawn` it.
    public func runApp(
        device: String,
        mode: FlutterBuildMode = .debug,
        flavor: String? = nil,
        entryPoint: String? = nil,
        dartDefines: [String: String] = [:],
        machine: Bool = false
    ) -> Self {
        operation(
            ["run", "-d", device, mode.flag] + optionalOption("--flavor", flavor) + optionalOption("--target", entryPoint)
                + dartDefines.sorted { $0.key < $1.key }.map { "--dart-define=\($0.key)=\($0.value)" }
                + flag("--machine", machine)
        )
    }

    // MARK: - Test

    /// `flutter test`.
    public func test(coverage: Bool = false) -> Self {
        operation(["test"] + flag("--coverage", coverage))
    }

    /// `flutter test --machine`: newline-delimited JSON events.
    public func testMachine(coverage: Bool = false, name: String? = nil) -> Self {
        operation(["test", "--machine"] + optionalOption("--name", name) + flag("--coverage", coverage))
    }

    /// `flutter test <paths> -d <device>`: `integration_test` on a device or simulator.
    public func integrationTest(
        device: String,
        paths: [String] = ["integration_test"],
        machine: Bool = true,
        flavor: String? = nil,
        name: String? = nil
    ) -> Self {
        operation(
            ["test"] + paths + ["-d", device] + flag("--machine", machine) + optionalOption("--flavor", flavor)
                + optionalOption("--name", name)
        )
    }

    /// `flutter drive --driver <driver> --target <target> -d <device>`.
    public func drive(driver: String, target: String, device: String, mode: FlutterBuildMode = .debug) -> Self {
        operation(["drive", "--driver", driver, "--target", target, "-d", device, mode.flag])
    }

    // MARK: - Toolchain

    /// `flutter --version`; `machine` emits JSON.
    public func version(machine: Bool = false) -> Self {
        operation(["--version"] + flag("--machine", machine))
    }

    /// `flutter doctor`.
    public func doctor(verbose: Bool = false) -> Self {
        operation(["doctor"] + flag("-v", verbose))
    }

    /// Any other `flutter` subcommand.
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

/// Targets accepted by `flutter build`.
public enum FlutterBuildTarget: String, Sendable, CaseIterable {
    case ios
    case ipa
    case apk
    case appbundle
    case iosFramework = "ios-framework"
    case macos
    case web
}

/// Build modes accepted by `flutter build`, `install`, and `run`.
public enum FlutterBuildMode: String, Sendable, CaseIterable {
    case debug
    case profile
    case release

    var flag: String { "--\(rawValue)" }
}
