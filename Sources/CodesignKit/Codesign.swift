import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for macOS `codesign`: sign, verify, and inspect app bundles and binaries.
///
/// ```swift
/// try await Codesign(context: shell).verify("Build/MyApp.app", deep: true, strict: true).run()
/// ```
public struct Codesign: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), executablePath: String = "codesign") {
        self.spec = CommandSpec(executable: executablePath, context: context)
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

    /// `codesign --force --sign <identity>`.
    ///
    /// - Parameters:
    ///   - identity: Certificate name or SHA-1 hash; `-` signs ad hoc.
    ///   - entitlements: Entitlements plist to embed.
    ///   - hardenedRuntime: `--options runtime`, required for notarization.
    ///   - timestamp: `--timestamp` (secure timestamp) or `--timestamp=none` when `false`.
    ///   - keychain: Restrict identity lookup to this keychain.
    public func sign(
        _ path: String,
        identity: String,
        entitlements: String? = nil,
        hardenedRuntime: Bool = false,
        timestamp: Bool? = nil,
        keychain: String? = nil,
        deep: Bool = false,
        preserveMetadata: [String] = []
    ) -> Self {
        var values = ["--force", "--sign", identity]
        values += optionalOption("--entitlements", entitlements)
        values += hardenedRuntime ? ["--options", "runtime"] : []
        if let timestamp {
            values.append(timestamp ? "--timestamp" : "--timestamp=none")
        }
        values += optionalOption("--keychain", keychain)
        values += flag("--deep", deep)
        if !preserveMetadata.isEmpty {
            values.append("--preserve-metadata=" + preserveMetadata.joined(separator: ","))
        }
        return operation(values + [path])
    }

    /// `codesign --verify`; exits non-zero when the signature is invalid.
    public func verify(_ path: String, deep: Bool = false, strict: Bool = false, verbosity: Int = 2) -> Self {
        operation(["--verify", "--verbose=\(verbosity)"] + flag("--deep", deep) + flag("--strict", strict) + [path])
    }

    /// `codesign --display --verbose`; the signing details are written to stderr.
    public func display(_ path: String, verbosity: Int = 4) -> Self {
        operation(["--display", "--verbose=\(verbosity)", path])
    }

    /// `codesign --display --entitlements - --xml`: the embedded entitlements as an XML plist on stdout.
    public func entitlements(_ path: String) -> Self {
        operation(["--display", "--entitlements", "-", "--xml", path])
    }

    /// `codesign --remove-signature`.
    public func removeSignature(_ path: String) -> Self {
        operation(["--remove-signature", path])
    }

    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
