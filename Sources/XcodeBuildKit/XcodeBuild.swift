import Foundation
import SwiftyShell
internal import WrapperSupport

/// A fluent wrapper for the `xcodebuild` command.
///
/// Prefer the operation methods such as ``build(clean:)``, ``test()``, and
/// ``exportArchive(archivePath:exportPath:exportOptionsPlist:)``. The generic
/// ``option(_:)`` and ``trailingArgument(_:)`` methods remain available for
/// options and operations not modeled by this package.
public struct XcodeBuild: RunnableCommandFamily {
    private var spec: CommandSpec
    private var options: [XcodeBuildOption] = []
    private var trailing: [String] = []
    private var settings: [XcodeBuildBuildSetting] = []
    private var operation: XcodeBuildOperation?

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates an `xcodebuild` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcodebuild") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `xcodebuild` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `xcodebuild` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Appends a typed `xcodebuild` option.
    public func option(_ option: XcodeBuildOption) -> Self {
        modified(self) { $0.options.append(option) }
    }

    /// Appends multiple typed `xcodebuild` options.
    public func options(_ values: [XcodeBuildOption]) -> Self {
        modified(self) { $0.options += values }
    }

    /// Selects an Xcode project or workspace, replacing any previously selected typed container.
    public func container(_ container: XcodeBuildContainer) -> Self {
        modified(self) { $0.options = $0.options.filter { !$0.isContainerOption } + [container.option] }
    }

    /// Selects an Xcode project, replacing any previously selected typed project or workspace.
    public func project(_ path: String) -> Self {
        container(.project(path))
    }

    /// Selects an Xcode workspace, replacing any previously selected typed project or workspace.
    public func workspace(_ path: String) -> Self {
        container(.workspace(path))
    }

    /// Appends a trailing argument.
    public func trailingArgument(_ value: String) -> Self {
        modified(self) { $0.trailing.append(value) }
    }

    /// Appends multiple trailing arguments.
    public func trailingArguments(_ values: [String]) -> Self {
        modified(self) { $0.trailing += values }
    }

    /// Adds a build setting in `NAME=VALUE` form.
    public func buildSetting(_ name: String, _ value: String) -> Self {
        modified(self) { $0.settings.append(XcodeBuildBuildSetting(name: name, value: value)) }
    }

    /// Adds multiple build settings.
    public func buildSettings(_ values: KeyValuePairs<String, String>) -> Self {
        modified(self) { $0.settings += values.map { XcodeBuildBuildSetting(name: $0.0, value: $0.1) } }
    }

    /// Configures the command to build, optionally cleaning before the build.
    public func build(clean: Bool = false) -> Self {
        select(.build(clean: clean))
    }

    /// Configures the command to run the test action.
    public func test() -> Self {
        select(.test)
    }

    /// Configures the command to run the `build-for-testing` action.
    ///
    /// Builds the app and test bundles once and writes an `.xctestrun` file to the build
    /// products directory, so tests can then run on one or more destinations with
    /// ``testWithoutBuilding()`` without recompiling. Combine with
    /// ``XcodeBuildOption/derivedDataPath(_:)`` for a predictable products location, or
    /// ``XcodeBuildOption/testProductsPath(_:)`` to bundle everything into one `.xctestproducts`.
    ///
    /// ```swift
    /// try await XcodeBuild(context: shell)
    ///     .workspace("App.xcworkspace")
    ///     .option(.scheme("App"))
    ///     .option(.destination("generic/platform=iOS Simulator"))
    ///     .option(.derivedDataPath("./build/DerivedData"))
    ///     .buildForTesting()
    ///     .run()
    /// ```
    public func buildForTesting() -> Self {
        select(.buildForTesting)
    }

    /// Configures the command to run the `test-without-building` action.
    ///
    /// Runs tests from products produced by ``buildForTesting()``. Pass either the scheme and
    /// container used for the build, or ``XcodeBuildOption/xctestrun(_:)`` /
    /// ``XcodeBuildOption/testProductsPath(_:)`` to run without the project.
    ///
    /// ```swift
    /// try await XcodeBuild(context: shell)
    ///     .option(.xctestrun("./build/DerivedData/Build/Products/App_iphonesimulator.xctestrun"))
    ///     .option(.destination("platform=iOS Simulator,name=iPhone 16"))
    ///     .testWithoutBuilding()
    ///     .run()
    /// ```
    public func testWithoutBuilding() -> Self {
        select(.testWithoutBuilding)
    }

    /// Configures the command to archive build products.
    /// - Parameter path: Optional destination path for the created `.xcarchive`.
    public func archive(path: String? = nil) -> Self {
        select(.archive(path: path))
    }

    /// Configures the command to export an existing archive.
    /// - Parameters:
    ///   - archivePath: Path to the `.xcarchive` to export.
    ///   - exportPath: Optional destination directory for exported products.
    ///   - exportOptionsPlist: Path to the export options property list.
    public func exportArchive(
        archivePath: String,
        exportPath: String? = nil,
        exportOptionsPlist: String
    ) -> Self {
        select(
            .exportArchive(
                archivePath: archivePath,
                exportPath: exportPath,
                exportOptionsPlist: exportOptionsPlist
            )
        )
    }

    /// Configures the command to display build settings.
    /// - Parameter json: Whether to request JSON output. `xcodebuild` also enables quiet output for JSON.
    public func showBuildSettings(json: Bool = false) -> Self {
        select(.showBuildSettings(json: json))
    }

    /// Configures the command to display destinations valid for the selected scheme.
    public func showDestinations() -> Self {
        select(.showDestinations)
    }

    /// Configures the command to create an XCFramework from prebuilt inputs.
    /// An empty `inputs` list produces an argv `xcodebuild` itself rejects; this wrapper does not trap.
    /// - Parameters:
    ///   - inputs: Frameworks and libraries to package. Library headers and debug symbols remain grouped with their input.
    ///   - output: Destination path for the `.xcframework`.
    ///   - allowInternalDistribution: Whether the result may contain metadata unsuitable for public distribution.
    public func createXCFramework(
        inputs: [XcodeBuildXCFrameworkInput],
        output: String,
        allowInternalDistribution: Bool = false
    ) -> Self {
        select(
            .createXCFramework(
                inputs: inputs,
                output: output,
                allowInternalDistribution: allowInternalDistribution
            )
        )
    }

    /// Configures the command to clean without building (`xcodebuild clean`).
    public func clean() -> Self {
        select(.clean)
    }

    /// Configures the command to run the static analyzer (`xcodebuild analyze`).
    public func analyze() -> Self {
        select(.analyze)
    }

    /// Configures the command to build DocC documentation (`xcodebuild docbuild`).
    public func docbuild() -> Self {
        select(.docbuild)
    }

    /// **Mutating**: resolves Swift package dependencies (`xcodebuild -resolvePackageDependencies`).
    ///
    /// Writes resolved state and fetches sources into the package cache or derived data.
    public func resolvePackageDependencies() -> Self {
        select(.resolvePackageDependencies)
    }

    /// Lists a container's targets, build configurations, and schemes (`xcodebuild -list [-json]`).
    ///
    /// Select the container with ``project(_:)`` or ``workspace(_:)`` first.
    public func list(json: Bool = false) -> Self {
        select(.list(json: json))
    }

    /// Reports the Xcode version and build (`xcodebuild -version`).
    public func version() -> Self {
        select(.version)
    }

    /// Builds the raw `xcodebuild` command.
    public func command() -> Command {
        var arguments: [String] = operation?.prefixArguments ?? []
        arguments += options.flatMap(\.arguments)
        arguments += operation?.argumentsAfterOptions ?? []
        arguments += settings.map(\.argument)
        arguments += operation?.buildActions ?? []
        arguments += trailing
        return modified(spec) { $0.arguments = arguments }.command()
    }

    private func select(_ value: XcodeBuildOperation) -> Self {
        modified(self) { $0.operation = value }
    }
}

struct XcodeBuildBuildSetting: Sendable, Equatable {
    let name: String
    let value: String

    var argument: String {
        "\(name)=\(value)"
    }
}
