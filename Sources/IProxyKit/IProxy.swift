import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for libusbmuxd's `iproxy`, which forwards a host TCP port to a port on a USB- or
/// network-attached iOS device. `devicectl` has no port forwarding, so this is how a host reaches
/// a server running on a physical device. Long-lived: `spawn` it and stop it when done.
///
/// ```swift
/// let tunnel = try await IProxy(context: shell).forward(localPort: 22087, devicePort: 22087, udid: udid).spawn()
/// ```
public struct IProxy: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), executablePath: String = "iproxy") {
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

    /// Forwards `localPort` to `devicePort` on the device with `udid`.
    ///
    /// - Parameters:
    ///   - network: Reach the device over the network instead of USB (`-n`).
    ///   - listenAddress: Host address to bind instead of all interfaces (`-s`).
    public func forward(
        localPort: Int,
        devicePort: Int,
        udid: String,
        network: Bool = false,
        listenAddress: String? = nil
    ) -> Self {
        modified(self) {
            $0.spec.arguments =
                ["\(localPort):\(devicePort)", "-u", udid] + flag("-n", network) + optionalOption("-s", listenAddress)
        }
    }

    /// `iproxy --version`, for availability probes.
    public func version() -> Self {
        modified(self) { $0.spec.arguments = ["--version"] }
    }

    public func command() -> Command {
        spec.command()
    }
}
