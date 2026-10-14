import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for the Android SDK's `sdkmanager`, which installs and updates SDK packages
/// (platforms, build tools, system images, the emulator).
///
/// Installing and accepting licenses mutate the machine; callers decide when that is allowed.
public struct SDKManager: RunnableCommandFamily {
    private var spec: CommandSpec
    private var options: [String] = []

    /// Candidate locations under the SDK root, newest layout first.
    public static let sdkRelativePaths = ["cmdline-tools/latest/bin/sdkmanager", "tools/bin/sdkmanager"]

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// - Parameter executablePath: Explicit path. When `nil`, uses the SDK named by
    ///   `ANDROID_HOME` / `ANDROID_SDK_ROOT`, else `sdkmanager` on `PATH`.
    public init(context: ShellContext = .init(), executablePath: String? = nil) {
        let executable =
            executablePath
            ?? AndroidSDK.executable(Self.sdkRelativePaths, fallback: "sdkmanager", environment: context.environment)
        self.spec = CommandSpec(executable: executable, context: context)
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

    // MARK: - Options

    /// `--sdk_root=<path>`.
    public func sdkRoot(_ path: String) -> Self {
        modified(self) { $0.options += ["--sdk_root=\(path)"] }
    }

    /// `--channel=<n>`: 0 stable, 1 beta, 2 dev, 3 canary.
    public func channel(_ value: Int) -> Self {
        modified(self) { $0.options += ["--channel=\(value)"] }
    }

    /// `--include_obsolete`.
    public func includeObsolete() -> Self {
        modified(self) { $0.options += ["--include_obsolete"] }
    }

    // MARK: - Operations

    /// `--list`; `installedOnly` uses `--list_installed`.
    public func list(installedOnly: Bool = false) -> Self {
        operation([installedOnly ? "--list_installed" : "--list"])
    }

    /// Installs packages such as `platform-tools` or `system-images;android-35;google_apis;arm64-v8a`.
    public func install(_ packages: [String]) -> Self {
        operation(packages)
    }

    /// `--uninstall <packages>`.
    public func uninstall(_ packages: [String]) -> Self {
        operation(["--uninstall"] + packages)
    }

    /// `--update`: updates every installed package.
    public func updateAll() -> Self {
        operation(["--update"])
    }

    /// `--licenses`: prompts for every unaccepted license. Feed `y` lines on stdin to accept them.
    public func licenses() -> Self {
        operation(["--licenses"])
    }

    /// `--version`.
    public func version() -> Self {
        operation(["--version"])
    }

    public func command() -> Command {
        modified(spec) { $0.arguments += options }.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
