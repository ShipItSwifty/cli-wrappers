import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for CocoaPods' `pod`, run by React Native, Flutter, and KMP iOS hosts before
/// `xcodebuild` builds the generated workspace.
///
/// ```swift
/// try await Pod(context: shell, bundler: true).install(deployment: true).workingDirectory("ios").run()
/// ```
public struct Pod: RunnableCommandFamily {
    private var spec: CommandSpec
    private var options: [String] = []

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// - Parameters:
    ///   - bundler: Run as `bundle exec pod`, so the version locked in the project's `Gemfile.lock` is used.
    ///   - executablePath: The `pod` executable (or, with `bundler`, `bundle`).
    public init(context: ShellContext = .init(), bundler: Bool = false, executablePath: String? = nil) {
        self.spec =
            bundler
            ? CommandSpec(executable: executablePath ?? "bundle", prefix: ["exec", "pod"], context: context)
            : CommandSpec(executable: executablePath ?? "pod", context: context)
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

    /// `--project-directory=<path>`: the directory holding the `Podfile`.
    public func projectDirectory(_ path: String) -> Self {
        modified(self) { $0.options += ["--project-directory=\(path)"] }
    }

    /// `--verbose`.
    public func verbose() -> Self {
        modified(self) { $0.options += ["--verbose"] }
    }

    /// `--no-ansi`, for logs.
    public func noANSI() -> Self {
        modified(self) { $0.options += ["--no-ansi"] }
    }

    // MARK: - Operations

    /// `pod install`.
    ///
    /// - Parameters:
    ///   - repoUpdate: Update spec repos first (`--repo-update`).
    ///   - deployment: Refuse to change `Podfile.lock` (`--deployment`), for CI.
    ///   - cleanInstall: Ignore the cache and reinstall every pod (`--clean-install`).
    public func install(repoUpdate: Bool = false, deployment: Bool = false, cleanInstall: Bool = false) -> Self {
        operation(
            ["install"] + flag("--repo-update", repoUpdate) + flag("--deployment", deployment)
                + flag("--clean-install", cleanInstall)
        )
    }

    /// `pod update [pods]`; every pod when empty.
    public func update(_ pods: [String] = [], repoUpdate: Bool = true) -> Self {
        operation(["update"] + pods + flag("--no-repo-update", !repoUpdate))
    }

    /// `pod repo update`.
    public func repoUpdate() -> Self {
        operation(["repo", "update"])
    }

    /// `pod deintegrate`.
    public func deintegrate() -> Self {
        operation(["deintegrate"])
    }

    /// `pod outdated`.
    public func outdated() -> Self {
        operation(["outdated"])
    }

    /// `pod --version`.
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
