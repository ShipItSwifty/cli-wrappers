import Foundation
import SwiftyShell
internal import WrapperSupport

/// A typed wrapper for the `frameit` command.
public struct Frameit: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates a `frameit` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "frameit") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `frameit` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `frameit` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Uses `frameit --path <screenshotsDirectory> --output <outputDirectory>`.
    public func render(screenshotsDirectory: String, outputDirectory: String) -> Self {
        operation(["--path", screenshotsDirectory, "--output", outputDirectory])
    }

    /// Builds the raw `frameit` command.
    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
