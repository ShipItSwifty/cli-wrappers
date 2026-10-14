import Foundation

/// Locates binaries inside an Android SDK, which does not put most of its tools on `PATH`.
public enum AndroidSDK {
    /// Environment keys that name the SDK root, in precedence order.
    public static let rootKeys = ["ANDROID_HOME", "ANDROID_SDK_ROOT"]

    /// SDK roots named by the environment, in precedence order.
    public static func roots(environment: [String: String]) -> [String] {
        rootKeys.compactMap { environment[$0] }.filter { !$0.isEmpty }
    }

    /// The first existing `<root>/<relativePath>` among the environment's SDK roots, else `fallback`
    /// (the bare tool name, resolved through `PATH`).
    ///
    /// - Parameters:
    ///   - relativePaths: Candidate locations under the SDK root, in preference order, e.g.
    ///     `["cmdline-tools/latest/bin/avdmanager", "tools/bin/avdmanager"]`.
    ///   - fallback: Executable used when no candidate exists.
    public static func executable(
        _ relativePaths: [String],
        fallback: String,
        environment: [String: String],
        fileExists: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> String {
        for root in roots(environment: environment) {
            for relative in relativePaths {
                let candidate = (root as NSString).appendingPathComponent(relative)
                if fileExists(candidate) {
                    return candidate
                }
            }
        }
        return fallback
    }
}
