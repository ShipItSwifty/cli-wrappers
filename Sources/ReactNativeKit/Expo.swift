import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for the Expo CLI (`expo`), run through the project's package runner.
///
/// Expo apps without committed `ios/` / `android/` folders need `prebuild` before a native build.
public struct Expo: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), runner: JSPackageRunner = .npx) {
        self.spec = CommandSpec(executable: runner.executable, prefix: runner.prefix + ["expo"], context: context)
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

    /// `expo prebuild`: generates native projects. `platform` is `ios`, `android`, or `all`.
    public func prebuild(platform: String = "all", clean: Bool = false, installPods: Bool = true) -> Self {
        operation(
            ["prebuild", "--platform", platform, "--non-interactive"] + flag("--clean", clean)
                + flag("--no-install", !installPods)
        )
    }

    /// `expo run:ios`.
    public func runIOS(device: String? = nil, configuration: String = "Debug", startBundler: Bool = true) -> Self {
        operation(
            ["run:ios", "--configuration", configuration] + optionalOption("--device", device)
                + flag("--no-bundler", !startBundler)
        )
    }

    /// `expo run:android`.
    public func runAndroid(device: String? = nil, variant: String = "debug", startBundler: Bool = true) -> Self {
        operation(
            ["run:android", "--variant", variant] + optionalOption("--device", device) + flag("--no-bundler", !startBundler)
        )
    }

    /// `expo start`: the dev server. Long-lived, so `spawn` it.
    public func start(port: Int? = nil, clear: Bool = false) -> Self {
        operation(["start"] + optionalOption("--port", port.map(String.init)) + flag("--clear", clear))
    }

    /// `expo export --platform <platform>`.
    public func export(platform: String, outputDirectory: String? = nil) -> Self {
        operation(["export", "--platform", platform] + optionalOption("--output-dir", outputDirectory))
    }

    /// `expo config --json`.
    public func config() -> Self {
        operation(["config", "--json"])
    }

    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
