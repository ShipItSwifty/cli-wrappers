import Foundation
import SwiftyShell
internal import WrapperSupport

/// A fluent wrapper for `./gradlew` (Gradle Wrapper) invocations.
///
/// **Mutating**: Gradle tasks build, write into the project's `build` directories and the Gradle
/// user home, and can publish artifacts or install onto devices, depending on the task selected.
///
/// Follows the same `RunnableCommandFamily` pattern as `XcodeBuild` and `Xcrun`.
/// All shell execution goes through the injected `ShellContext`.
///
/// ## Resolution Order for the gradlew executable
/// 1. `executablePath` passed to ``init(context:executablePath:fileExists:)``, or a path set later
///    with ``settingGradlewPath(_:)``
/// 2. `./gradlew` relative to `projectDir` (or current directory), checked with the injected
///    `fileExists` predicate
/// 3. `gradle` on `PATH` as a fallback
///
/// ## Usage
/// ```swift
/// // Build a release AAB
/// let output = try await Gradle(context: context.shell)
///     .projectDir("./android")
///     .task(.bundleRelease)
///     .flag(.noDaemon)
///     .flag(.buildCache)
///     .run()
///
/// // Run unit tests
/// let result = try await Gradle(context: context.shell)
///     .task(.testDebugUnitTest)
///     .flag(.noDaemon)
///     .run()
/// ```
///
/// ## Streaming long builds
/// For long-running builds (e.g. `bundle<Variant>` can take many minutes), route stdout/stderr
/// to ``SwiftyShell/OutputDestination/tee`` so progress is echoed live to the parent process
/// while still being captured for parsing, and lift the capture limit so verbose output does not
/// trip the default cap:
/// ```swift
/// let output = try await Gradle(context: context.shell)
///     .task(.bundleRelease)
///     .settingStdoutDestination(.tee)
///     .settingStderrDestination(.tee)
///     .outputLimit(0)
///     .run()
/// ```
public struct Gradle: RunnableCommandFamily {
    private var spec: CommandSpec
    private var taskList: [GradleTask] = []
    private var propertyList: [GradleProperty] = []
    private var flagList: [GradleFlag] = []
    private var explicitGradlewPath: String?
    private var projectDirectory: String?
    private var jvmArguments: String?
    private let fileExists: @Sendable (String) -> Bool

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    // MARK: - Init

    /// Creates a `Gradle` command family bound to a shell context.
    ///
    /// - Parameters:
    ///   - context: Shell execution context.
    ///   - executablePath: Explicit `gradlew` (or `gradle`) path. When `nil`, `./gradlew` under the
    ///     project directory is used if it exists, else `gradle` on `PATH`.
    ///   - fileExists: Predicate used to look for `gradlew`. Injected so tests never touch the
    ///     file system.
    public init(
        context: ShellContext = .init(),
        executablePath: String? = nil,
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        self.spec = CommandSpec(executable: "gradle", context: context)
        self.explicitGradlewPath = executablePath
        self.fileExists = fileExists
    }

    // MARK: - Fluent API

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `gradlew` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `gradlew` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Appends a Gradle task (e.g. `.assembleRelease`, `.bundleRelease`).
    public func task(_ task: GradleTask) -> Self {
        modified(self) { $0.taskList.append(task) }
    }

    /// Appends multiple Gradle tasks.
    public func tasks(_ values: [GradleTask]) -> Self {
        modified(self) { $0.taskList += values }
    }

    /// Appends a `-P` project property.
    public func property(_ property: GradleProperty) -> Self {
        modified(self) { $0.propertyList.append(property) }
    }

    /// Appends multiple `-P` project properties.
    public func properties(_ values: [GradleProperty]) -> Self {
        modified(self) { $0.propertyList += values }
    }

    /// Appends a Gradle flag (e.g. `.noDaemon`, `.buildCache`).
    public func flag(_ flag: GradleFlag) -> Self {
        modified(self) { $0.flagList.append(flag) }
    }

    /// Appends multiple Gradle flags.
    public func flags(_ values: [GradleFlag]) -> Self {
        modified(self) { $0.flagList += values }
    }

    /// Sets an explicit path to the `gradlew` script.
    /// When nil (default), the wrapper is auto-detected.
    public func settingGradlewPath(_ path: String?) -> Self {
        modified(self) { $0.explicitGradlewPath = path }
    }

    /// Sets the Gradle project directory.
    /// Defaults to the current working directory when nil.
    public func projectDir(_ dir: String) -> Self {
        modified(self) { $0.projectDirectory = dir }
    }

    /// Sets JVM arguments via `-Dorg.gradle.jvmargs`.
    public func jvmArgs(_ args: String) -> Self {
        modified(self) { $0.jvmArguments = args }
    }

    // MARK: - RunnableCommandFamily

    /// Builds the raw `gradlew` (or `gradle`) command.
    public func command() -> Command {
        modified(spec) { built in
            built.executable = resolveGradlew()

            // Flags come first (e.g. --no-daemon), then the JVM args system property, `-P`
            // properties, and task names each followed by their task-level options (`--tests`).
            var arguments = flagList.flatMap(\.arguments)
            if let jvmArguments {
                arguments.append("-Dorg.gradle.jvmargs=\(jvmArguments)")
            }
            arguments += propertyList.map(\.argument)
            arguments += taskList.flatMap(\.arguments)
            built.arguments = arguments

            // Gradle resolves its project root (settings.gradle) from the process's working
            // directory, not from the wrapper script's location. When projectDir points somewhere
            // other than the process cwd (e.g. a React Native project's `./android` subdirectory),
            // the invocation must run with that directory as its cwd or Gradle reports "does not
            // contain a Gradle build" even though the wrapper was found correctly. An explicit
            // working directory on the configuration wins.
            if let projectDirectory, built.config.workingDirectoryOverride == nil {
                built.config = built.config.workingDirectory(projectDirectory)
            }
        }.command()
    }

    // MARK: - Private

    private func resolveGradlew() -> String {
        if let explicitGradlewPath { return explicitGradlewPath }

        let dir = projectDirectory ?? "."
        let candidate = "\(dir)/gradlew"
        if fileExists(candidate) {
            // Resolve to an absolute path now, against the process's current cwd: the child
            // process may run with `projectDir` as its working directory, which would otherwise
            // make this relative path resolve against the wrong base.
            return URL(fileURLWithPath: candidate).path
        }

        return "gradle"
    }
}
