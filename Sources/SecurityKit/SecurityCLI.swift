import Foundation
import SwiftyShell
internal import WrapperSupport

/// A typed wrapper for macOS `security` CLI commands.
///
/// Use this command family for all keychain and certificate operations instead of
/// constructing raw `Command("security", ...)` values at call sites.
///
/// > Important: `security` accepts passwords only as command-line arguments (`-p`, `-P`, `-k`),
/// > which every local user can read from the process list while the command runs. It has no
/// > option to read them from a file or environment variable. Where the tool can prompt instead
/// > (``createKeychain(name:)`` and ``unlockKeychain(name:)``), prefer the prompting form; on
/// > shared machines run these commands only on isolated, single-user hosts such as CI runners.
public struct SecurityCLI: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates a `security` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "security") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `security` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `security` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Uses the `security help` subcommand.
    public func help(_ subject: String? = nil) -> Self {
        var values = ["help"]
        if let subject {
            values.append(subject)
        }
        return operation(values)
    }

    /// **Mutating**: uses the `security create-keychain` subcommand, prompting for the password.
    ///
    /// Omits `-p`, so the password is read from the terminal rather than passed in argv.
    public func createKeychain(name: String) -> Self {
        operation(["create-keychain", name])
    }

    /// **Mutating**: uses the `security create-keychain` subcommand.
    ///
    /// > Warning: `password` is passed with `-p` and is visible in the process list.
    public func createKeychain(name: String, password: String) -> Self {
        operation(["create-keychain", "-p", password, name])
    }

    /// **Mutating**: uses the `security set-keychain-settings` subcommand.
    public func setKeychainSettings(name: String, timeout: Int) -> Self {
        operation(["set-keychain-settings", "-lut", String(timeout), name])
    }

    /// **Mutating**: uses the `security list-keychains -d user -s ...` subcommand.
    public func setUserKeychainSearchList(_ keychains: [String]) -> Self {
        operation(["list-keychains", "-d", "user", "-s"] + keychains)
    }

    /// **Mutating**: uses the `security import` subcommand for a certificate file.
    ///
    /// > Warning: `password` is passed with `-P` and is visible in the process list.
    public func importCertificate(
        at path: String,
        keychainName: String,
        password: String,
        trustedApplications: [String]
    ) -> Self {
        var values = ["import", path, "-k", keychainName, "-P", password]
        for application in trustedApplications {
            values.append(contentsOf: ["-T", application])
        }
        return operation(values)
    }

    /// **Mutating**: uses the `security set-key-partition-list` subcommand.
    ///
    /// > Warning: `password` is passed with `-k` and is visible in the process list.
    public func setKeyPartitionList(services: String, password: String, keychainName: String) -> Self {
        operation(["set-key-partition-list", "-S", services, "-s", "-k", password, keychainName])
    }

    /// **Mutating**: uses the `security unlock-keychain` subcommand, prompting for the password.
    ///
    /// Omits `-p`, so the password is read from the terminal rather than passed in argv.
    public func unlockKeychain(name: String) -> Self {
        operation(["unlock-keychain", name])
    }

    /// **Mutating**: uses the `security unlock-keychain` subcommand.
    ///
    /// > Warning: `password` is passed with `-p` and is visible in the process list.
    public func unlockKeychain(name: String, password: String) -> Self {
        operation(["unlock-keychain", "-p", password, name])
    }

    /// **Mutating**: uses the `security delete-keychain` subcommand.
    public func deleteKeychain(name: String) -> Self {
        operation(["delete-keychain", name])
    }

    /// Builds the raw `security` command.
    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
