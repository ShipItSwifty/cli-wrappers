import Foundation
import SwiftyShell

/// The state every simple command family carries: which executable to run, the argv built so far,
/// output handling, and shared tool configuration.
///
/// Wrappers hold one privately and forward the `RunnableCommandFamily` requirements to it, so
/// each wrapper only declares the operations of its tool.
public struct CommandSpec: Sendable, Equatable {
    /// Executable name or path, resolved through `PATH` when it has no slash.
    public var executable: String
    /// Arguments placed before every operation (for example `exec pod` under `bundle`).
    public var prefix: [String]
    /// Global options that precede the operation, such as Bazel startup options.
    public var globalArguments: [String]
    /// The selected operation and its arguments.
    public var arguments: [String]
    /// Arguments appended after a `--` separator, when present.
    public var passthroughArguments: [String]
    public var stdout: OutputDestination
    public var stderr: OutputDestination
    public var config: ToolConfiguration

    public init(executable: String, prefix: [String] = [], context: ShellContext) {
        self.executable = executable
        self.prefix = prefix
        self.globalArguments = []
        self.arguments = []
        self.passthroughArguments = []
        self.stdout = .capture
        self.stderr = .capture
        self.config = ToolConfiguration(context: context)
    }

    /// The full argv after the executable.
    public var argv: [String] {
        prefix + globalArguments + arguments + (passthroughArguments.isEmpty ? [] : ["--"] + passthroughArguments)
    }

    /// Builds the command with configuration overrides applied.
    public func command() -> Command {
        config.apply(to: Command(executable).args(argv).stdout(stdout).stderr(stderr))
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.executable == rhs.executable && lhs.argv == rhs.argv
    }
}

/// Appends `--name=value` when `value` is present.
public func optionalFlag(_ name: String, _ value: String?) -> [String] {
    value.map { ["\(name)=\($0)"] } ?? []
}

/// Appends `name value` when `value` is present.
public func optionalOption(_ name: String, _ value: String?) -> [String] {
    value.map { [name, $0] } ?? []
}

/// Appends `name` when `enabled`.
public func flag(_ name: String, _ enabled: Bool) -> [String] {
    enabled ? [name] : []
}

/// Returns a copy of `value` with `update` applied, for fluent `-> Self` builders.
public func modified<Value>(_ value: Value, _ update: (inout Value) -> Void) -> Value {
    var copy = value
    update(&copy)
    return copy
}
