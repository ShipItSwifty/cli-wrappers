import Foundation
import Logging
import SwiftyShell
internal import WrapperSupport

/// A discovered xcodebuild destination for running tests.
public struct XcodebuildDestination: Codable, Sendable, Hashable {
    /// Platform identifier, e.g. `"iOS Simulator"`, `"iOS"`, `"macOS"`.
    public let platform: String
    /// Human-readable device or simulator name, e.g. `"iPhone 16 Pro"`.
    public let name: String
    /// Operating system version string, e.g. `"18.2"`.
    public let os: String?
    /// Device UDID (present for physical devices and booted simulators).
    public let udid: String?
    /// Whether this is a simulator (`true`) or a physical device (`false`).
    public var isSimulator: Bool { platform.contains("Simulator") }

    /// The full xcodebuild `-destination` string for this destination.
    ///
    /// Uses `platform=<platform>,id=<udid>` when a UDID is known, since two simulators can share
    /// a name and OS version and only the identifier selects one. Without a UDID it falls back to
    /// `platform`, `name`, and `OS`.
    public var destinationString: String {
        if let udid, !udid.isEmpty {
            return "platform=\(platform),id=\(udid)"
        }
        var parts = ["platform=\(platform)", "name=\(name)"]
        if let os {
            parts.append("OS=\(os)")
        }
        return parts.joined(separator: ",")
    }

    public init(platform: String, name: String, os: String? = nil, udid: String? = nil) {
        self.platform = platform
        self.name = name
        self.os = os
        self.udid = udid
    }
}

/// Discovers available xcodebuild destinations for a given scheme and Xcode container.
///
/// Uses `xcodebuild -showdestinations` to enumerate all destinations that are valid
/// for the specified scheme. The output is parsed into typed `XcodebuildDestination`
/// values that can be presented to the user or saved into workflow config.
///
/// ## Usage
/// ```swift
/// let discoverer = DestinationDiscovery(shell: context.shell)
/// let destinations = try await discoverer.availableDestinations(
///     scheme: "MyApp",
///     workspace: "MyApp.xcworkspace"
/// )
/// let simulators = destinations.filter(\.isSimulator)
/// ```
public struct DestinationDiscovery: Sendable {
    private let shell: ShellContext
    private let logger = Logger.forType(DestinationDiscovery.self)

    public init(shell: ShellContext) {
        self.shell = shell
    }

    /// Returns all available destinations for the given scheme and Xcode container.
    ///
    /// - Parameters:
    ///   - scheme: The Xcode scheme to query destinations for.
    ///   - workspace: Path to the `.xcworkspace` (preferred when present).
    ///   - project: Path to the `.xcodeproj` (used when no workspace is given).
    /// - Returns: Array of available destinations, sorted simulators first then devices.
    /// - Throws: The `ShellError` from `xcodebuild` when it fails and its output holds no
    ///   destination. Use ``parseDestinations(from:)`` to apply a different policy, such as
    ///   treating that failure as an empty list.
    public func availableDestinations(
        scheme: String,
        workspace: String? = nil,
        project: String? = nil
    ) async throws -> [XcodebuildDestination] {
        logger.info("Discovering destinations for scheme '\(scheme)'")

        var xcodeBuild = XcodeBuild(context: shell)
            .option(.scheme(scheme))
            .option(.quiet)
            .showDestinations()

        if let workspace {
            xcodeBuild = xcodeBuild.workspace(workspace)
        } else if let project {
            xcodeBuild = xcodeBuild.project(project)
        }

        let output: ShellOutput
        do {
            output = try await xcodeBuild.run()
        } catch let ShellError.exitFailure(command, shellOutput) {
            // xcodebuild -showdestinations exits non-zero on some Xcode versions even
            // when it successfully lists destinations; try to parse whatever we got.
            let combined = [shellOutput.stdout, shellOutput.stderr]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            let parsed = Self.parseDestinations(from: combined)
            if !parsed.isEmpty {
                logger.info("Parsed \(parsed.count) destination(s) from non-zero exit output")
                return parsed
            }
            logger.error("xcodebuild -showdestinations failed and listed no destinations", metadata: ["scheme": "\(scheme)"])
            throw ShellError.exitFailure(command: command, output: shellOutput)
        }

        let combined = [output.stdout, output.stderr]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let destinations = Self.parseDestinations(from: combined)
        logger.info("Found \(destinations.count) destination(s) for scheme '\(scheme)'")
        return destinations
    }

    // MARK: - Parsing

    // Regex values are immutable once built but not yet marked `Sendable`; they are compiled once here.
    nonisolated(unsafe) private static let blockPattern = /\{([^}]+)\}/
    nonisolated(unsafe) private static let fieldSeparator = /,\s*(?=(?:platform|id|OS|name|variant|arch|error):)/

    /// Parses `xcodebuild -showdestinations` output into typed destination values.
    ///
    /// The output format is a series of lines like:
    /// ```
    ///     { platform:iOS Simulator, id:..., OS:18.2, name:iPhone 16 Pro }
    ///     { platform:iOS, id:..., name:My iPhone }
    /// ```
    /// Each `{ ... }` block represents one destination. Blocks with an `error:` field are skipped.
    /// Simulators sort before physical devices, each group by name.
    public static func parseDestinations(from output: String) -> [XcodebuildDestination] {
        let destinations = output.matches(of: blockPattern).compactMap { parseBlock(String($0.output.1)) }

        return destinations.sorted { lhs, rhs in
            if lhs.isSimulator != rhs.isSimulator { return lhs.isSimulator }
            return lhs.name < rhs.name
        }
    }

    /// Parses a single `key:value, key:value` block into an `XcodebuildDestination`.
    ///
    /// Values may contain spaces and commas, so the block is split only on `, <known-key>:`.
    private static func parseBlock(_ block: String) -> XcodebuildDestination? {
        var kvPairs: [String: String] = [:]

        for segment in block.split(separator: fieldSeparator) {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard let colonIdx = trimmed.firstIndex(of: ":") else { continue }
            let key = String(trimmed[trimmed.startIndex..<colonIdx]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
            kvPairs[key] = value
        }

        guard let platform = kvPairs["platform"], !platform.isEmpty,
            let name = kvPairs["name"], !name.isEmpty
        else { return nil }

        if kvPairs["error"] != nil { return nil }

        return XcodebuildDestination(
            platform: platform,
            name: name,
            os: kvPairs["OS"],
            udid: kvPairs["id"]
        )
    }
}
