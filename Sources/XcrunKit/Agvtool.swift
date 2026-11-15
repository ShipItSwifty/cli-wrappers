import Foundation
import SwiftyShell
internal import WrapperSupport

/// A typed wrapper for `xcrun agvtool` commands.
public struct Agvtool: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates a `xcrun agvtool` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcrun") {
        self.spec = CommandSpec(executable: executablePath, prefix: ["agvtool"], context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `xcrun agvtool` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `xcrun agvtool` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Uses `agvtool what-marketing-version -terse`.
    public func whatMarketingVersionTerse() -> Self {
        operation(["what-marketing-version", "-terse"])
    }

    /// Uses `agvtool what-version -terse`.
    public func whatVersionTerse() -> Self {
        operation(["what-version", "-terse"])
    }

    /// **Mutating**: Uses `agvtool new-marketing-version <version>`.
    public func newMarketingVersion(_ version: String) -> Self {
        operation(["new-marketing-version", version])
    }

    /// **Mutating**: Uses `agvtool new-version -all <build>`.
    public func newVersionAll(_ build: String) -> Self {
        operation(["new-version", "-all", build])
    }

    /// Builds the raw `xcrun agvtool` command.
    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
