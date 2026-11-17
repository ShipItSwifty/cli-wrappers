import Foundation
import SwiftyShell
internal import WrapperSupport

/// A typed wrapper for `xcrun llvm-cov` commands.
public struct LLVMCov: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates an `xcrun llvm-cov` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The `xcrun` executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcrun") {
        self.spec = CommandSpec(executable: executablePath, prefix: ["llvm-cov"], context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `xcrun llvm-cov` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `xcrun llvm-cov` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Uses `llvm-cov report [-instr-profile=<path>] <binary>` to print a coverage summary.
    public func report(binary: String, instrumentProfile: String? = nil) -> Self {
        operation(["report"] + optionalFlag("-instr-profile", instrumentProfile) + [binary])
    }

    /// Uses `llvm-cov show [-instr-profile=<path>] <binary>` to display source coverage.
    public func show(binary: String, instrumentProfile: String? = nil) -> Self {
        operation(["show"] + optionalFlag("-instr-profile", instrumentProfile) + [binary])
    }

    /// Builds the raw `xcrun llvm-cov` command.
    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
