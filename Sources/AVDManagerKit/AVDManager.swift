import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for the Android SDK's `avdmanager`, which creates and lists Android Virtual
/// Devices. Booting an AVD is `EmulatorKit`'s job.
public struct AVDManager: RunnableCommandFamily {
    private var spec: CommandSpec

    /// Candidate locations under the SDK root, newest layout first.
    public static let sdkRelativePaths = ["cmdline-tools/latest/bin/avdmanager", "tools/bin/avdmanager"]

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// - Parameter executablePath: Explicit path. When `nil`, uses the SDK named by
    ///   `ANDROID_HOME` / `ANDROID_SDK_ROOT`, else `avdmanager` on `PATH`.
    public init(context: ShellContext = .init(), executablePath: String? = nil) {
        let executable =
            executablePath
            ?? AndroidSDK.executable(Self.sdkRelativePaths, fallback: "avdmanager", environment: context.environment)
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

    /// `list avd`; `compact` prints one name per line.
    public func listAVDs(compact: Bool = true) -> Self {
        operation(["list", "avd"] + flag("-c", compact))
    }

    /// `list device` (hardware profiles).
    public func listDeviceProfiles(compact: Bool = true) -> Self {
        operation(["list", "device"] + flag("-c", compact))
    }

    /// `list target`.
    public func listTargets(compact: Bool = true) -> Self {
        operation(["list", "target"] + flag("-c", compact))
    }

    /// `create avd`.
    ///
    /// - Parameters:
    ///   - systemImage: SDK package, e.g. `system-images;android-35;google_apis;arm64-v8a`.
    ///   - deviceProfile: Hardware profile id or name, e.g. `pixel_8`.
    ///   - force: Overwrite an AVD with the same name.
    public func createAVD(
        name: String,
        systemImage: String,
        deviceProfile: String? = nil,
        sdcard: String? = nil,
        path: String? = nil,
        force: Bool = false
    ) -> Self {
        operation(
            ["create", "avd", "--name", name, "--package", systemImage]
                + optionalOption("--device", deviceProfile) + optionalOption("--sdcard", sdcard)
                + optionalOption("--path", path) + flag("--force", force)
        )
    }

    /// `delete avd`.
    public func deleteAVD(name: String) -> Self {
        operation(["delete", "avd", "--name", name])
    }

    /// `move avd`, renaming and/or relocating it.
    public func moveAVD(name: String, renameTo newName: String? = nil, path: String? = nil) -> Self {
        operation(["move", "avd", "--name", name] + optionalOption("--rename", newName) + optionalOption("--path", path))
    }

    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
