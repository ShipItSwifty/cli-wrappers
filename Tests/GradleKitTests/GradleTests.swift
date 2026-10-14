import Foundation
import SwiftyShell
import Synchronization
import Testing

@testable import GradleKit

// MARK: - Gradle command builder tests

@Suite("Gradle")
struct GradleTests {
    @Test("Gradle builds command with a single task")
    func singleTask() {
        let command = Gradle()
            .task(.assembleRelease)
            .command()

        // executable is "gradle" when ./gradlew doesn't exist on disk (test environment)
        let exec = command.executableName
        #expect(exec == "gradle" || exec == "./gradlew")
        #expect(command.arguments.contains("assembleRelease"))
    }

    @Test("Gradle builds command with multiple tasks")
    func multipleTasks() {
        let command = Gradle()
            .task(.clean)
            .task(.bundleRelease)
            .command()

        let args = command.arguments
        #expect(args.contains("clean"))
        #expect(args.contains("bundleRelease"))
        // clean should come before bundleRelease
        let cleanIndex = args.firstIndex(of: "clean")
        let bundleIndex = args.firstIndex(of: "bundleRelease")
        #expect(cleanIndex != nil && bundleIndex != nil)
        if let ci = cleanIndex, let bi = bundleIndex {
            #expect(ci < bi)
        }
    }

    @Test("Gradle appends --no-daemon flag")
    func noDaemonFlag() {
        let command = Gradle()
            .task(.assembleRelease)
            .flag(.noDaemon)
            .command()

        #expect(command.arguments.contains("--no-daemon"))
    }

    @Test("Gradle appends --build-cache flag")
    func buildCacheFlag() {
        let command = Gradle()
            .task(.assembleRelease)
            .flag(.buildCache)
            .command()

        #expect(command.arguments.contains("--build-cache"))
    }

    @Test("Gradle appends -P property")
    func property() {
        let command = Gradle()
            .task(.assembleRelease)
            .property(.init(key: "versionCode", value: "42"))
            .command()

        #expect(command.arguments.contains("-PversionCode=42"))
    }

    @Test("Gradle uses custom gradlew path when set")
    func customGradlewPath() {
        let command = Gradle()
            .settingGradlewPath("/opt/project/gradlew")
            .task(.assembleRelease)
            .command()

        #expect(command.executableName == "/opt/project/gradlew")
    }

    @Test("Gradle resolves gradlew from project directory")
    func projectDir() {
        // projectDir affects gradlew resolution, not argument list
        let gradle = Gradle()
            .projectDir("./android")
            .task(.assembleDebug)
        let command = gradle.command()

        // task should still be in args
        #expect(command.arguments.contains("assembleDebug"))
        // executable should look in ./android/gradlew first (may fall back to gradle when not on disk)
        let exec = command.executableName
        #expect(exec == "./android/gradlew" || exec == "gradle")
    }

    @Test("Gradle runs and returns output via mock executor")
    func runsViaMockExecutor() async throws {
        let captured = Mutex<[String]>([])
        let executor = MockExecutor { command, _ in
            captured.withLock { $0.append(command.description) }
            return ShellOutput(stdout: "BUILD SUCCESSFUL in 2s\n", stderr: "", exitCode: 0)
        }
        let context = ShellContext(executor: executor)
        let output = try await Gradle(context: context)
            .task(.assembleRelease)
            .run()

        #expect(output.exitCode == 0)
        #expect(output.stdout.contains("BUILD SUCCESSFUL"))
        let cmds = captured.withLock { $0 }
        #expect(cmds.count == 1)
        #expect(cmds.first?.contains("assembleRelease") == true)
    }

    @Test("GradleTask flavor+variant assemble generates correct task name")
    func flavorAssembleTask() {
        let task = GradleTask.assemble(flavor: "free", variant: "release")
        #expect(task.name == "assembleFreeRelease")
    }

    @Test("GradleTask flavor+variant bundle generates correct task name")
    func flavorBundleTask() {
        let task = GradleTask.bundle(flavor: "paid", variant: "debug")
        #expect(task.name == "bundlePaidDebug")
    }
}
