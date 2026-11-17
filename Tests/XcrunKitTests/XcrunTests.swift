import Foundation
import Testing

@testable import XcrunKit

struct XcrunTests {
    @Test func buildsTypedCommandWithOptionsAndToolArguments() {
        let command = Xcrun()
            .option(.sdk("iphonesimulator"))
            .option(.find)
            .tool("simctl")
            .command()

        #expect(command.executableName == "xcrun")
        #expect(
            command.arguments == [
                "--sdk", "iphonesimulator",
                "--find",
                "simctl",
            ])
    }

    @Test func buildsSimctlListCommand() {
        let command = Xcrun()
            .simctl()
            .list(.devices, json: true)
            .buildCommand()

        #expect(command.executableName == "xcrun")
        #expect(
            command.arguments == [
                "simctl",
                "list",
                "devices",
                "--json",
            ])
    }

    @Test func buildsSimctlRuntimeAndIOCommands() {
        let runtime = Simctl()
            .runtime(arguments: ["list"])
            .buildCommand()
        let io = Simctl()
            .io("booted", command: "recordVideo", arguments: ["/tmp/out.mp4"])
            .buildCommand()

        #expect(runtime.arguments == ["simctl", "runtime", "list"])
        #expect(io.arguments == ["simctl", "io", "booted", "recordVideo", "/tmp/out.mp4"])
    }

    @Test func buildsSimctlUpgradeCommand() {
        let command = Simctl()
            .upgrade(["device-uuid-1", "device-uuid-2"])
            .buildCommand()

        #expect(command.arguments == ["simctl", "upgrade", "device-uuid-1", "device-uuid-2"])
    }

    #if os(macOS)
    /// Runs the real tool, so it needs an Xcode toolchain.
    @Test func runsVersionCommand() async throws {
        let output = try await Xcrun()
            .option(.version)
            .run()

        #expect(output.stdout.contains("xcrun version"))
        #expect(output.exitCode == 0)
    }
    #endif
}

struct SimctlLaunchTests {
    @Test func launchRendersFlagsBeforeDeviceAndArgumentsAfterBundle() {
        let command = Simctl(executablePath: "xcrun")
            .launch(
                "booted", bundleIdentifier: "com.example.app", arguments: ["-ui-test", "1"],
                environment: ["MODE": "test"], terminateRunning: true, waitForDebugger: true, console: .pty
            )
            .buildCommand()

        #expect(
            command.arguments == [
                "simctl", "launch", "--terminate-running-process", "--wait-for-debugger", "--console-pty",
                "booted", "com.example.app", "-ui-test", "1",
            ])
        #expect(command.environmentOverrides == ["SIMCTL_CHILD_MODE": "test"])
    }

    @Test func plainLaunchIsUnchanged() {
        let command = Simctl(executablePath: "xcrun").launch("booted", bundleIdentifier: "com.example.app").buildCommand()
        #expect(command.arguments == ["simctl", "launch", "booted", "com.example.app"])
        #expect(command.environmentOverrides.isEmpty)
    }

    @Test(
        "bootstatus renders -b after the device",
        arguments: [(false, ["simctl", "bootstatus", "UDID"]), (true, ["simctl", "bootstatus", "UDID", "-b"])]
    )
    func bootStatus(boot: Bool, expected: [String]) {
        #expect(Simctl(executablePath: "xcrun").bootStatus("UDID", boot: boot).buildCommand().arguments == expected)
    }
}

struct SimctlCatalogTests {
    private let simctl = Simctl(executablePath: "xcrun")

    @Test(
        "Every typed simctl operation emits its full argv",
        arguments: [
            (Simctl(executablePath: "xcrun").boot("U"), ["simctl", "boot", "U"]),
            (Simctl(executablePath: "xcrun").shutdown(["U", "V"]), ["simctl", "shutdown", "U", "V"]),
            (Simctl(executablePath: "xcrun").erase(["all"]), ["simctl", "erase", "all"]),
            (Simctl(executablePath: "xcrun").create(name: "N", deviceType: "T", runtime: "R"), ["simctl", "create", "N", "T", "R"]),
            (Simctl(executablePath: "xcrun").clone("U", to: "N"), ["simctl", "clone", "U", "N"]),
            (Simctl(executablePath: "xcrun").delete(["unavailable"]), ["simctl", "delete", "unavailable"]),
            (Simctl(executablePath: "xcrun").rename("U", to: "N"), ["simctl", "rename", "U", "N"]),
            (Simctl(executablePath: "xcrun").install("U", appAt: "/a.app"), ["simctl", "install", "U", "/a.app"]),
            (Simctl(executablePath: "xcrun").uninstall("U", bundleIdentifier: "b"), ["simctl", "uninstall", "U", "b"]),
            (Simctl(executablePath: "xcrun").terminate("U", bundleIdentifier: "b"), ["simctl", "terminate", "U", "b"]),
            (
                Simctl(executablePath: "xcrun").spawn("U", executable: "/bin/ls", arguments: ["-l"]),
                ["simctl", "spawn", "U", "/bin/ls", "-l"]
            ),
            (Simctl(executablePath: "xcrun").openURL("U", "https://example.com"), ["simctl", "openurl", "U", "https://example.com"]),
            (Simctl(executablePath: "xcrun").getenv("U", variable: "HOME"), ["simctl", "getenv", "U", "HOME"]),
            (Simctl(executablePath: "xcrun").listApps("U"), ["simctl", "listapps", "U"]),
            (Simctl(executablePath: "xcrun").appInfo("U", bundleIdentifier: "b"), ["simctl", "appinfo", "U", "b"]),
            (Simctl(executablePath: "xcrun").addMedia("U", files: ["a.png", "b.mov"]), ["simctl", "addmedia", "U", "a.png", "b.mov"]),
            (Simctl(executablePath: "xcrun").pbcopy("U"), ["simctl", "pbcopy", "U"]),
            (Simctl(executablePath: "xcrun").pbpaste("U"), ["simctl", "pbpaste", "U"]),
            (
                Simctl(executablePath: "xcrun").privacy("U", action: "grant", service: "photos", bundleIdentifier: "b"),
                ["simctl", "privacy", "U", "grant", "photos", "b"]
            ),
            (Simctl(executablePath: "xcrun").privacy("U", action: "reset", service: "all"), ["simctl", "privacy", "U", "reset", "all"]),
            (Simctl(executablePath: "xcrun").statusBar("U", arguments: ["clear"]), ["simctl", "status_bar", "U", "clear"]),
            (
                Simctl(executablePath: "xcrun").push("U", bundleIdentifier: "b", payloadAt: "p.json"),
                ["simctl", "push", "U", "b", "p.json"]
            ),
            (Simctl(executablePath: "xcrun").notifyPost("U", notification: "n"), ["simctl", "notify_post", "U", "n"]),
            (Simctl(executablePath: "xcrun").icloudSync("U"), ["simctl", "icloud_sync", "U"]),
            (Simctl(executablePath: "xcrun").upgrade(["U"]), ["simctl", "upgrade", "U"]),
            (Simctl(executablePath: "xcrun").pair("W", with: "P"), ["simctl", "pair", "W", "P"]),
            (Simctl(executablePath: "xcrun").unpair("W"), ["simctl", "unpair", "W"]),
        ] as [(Simctl, [String])]
    )
    func operations(simctl: Simctl, expected: [String]) {
        #expect(simctl.command().arguments == expected)
    }

    @Test func selectingAnOperationKeepsTrailingArgumentsAfterIt() {
        #expect(simctl.boot("U").arg("--arch=arm64").command().arguments == ["simctl", "boot", "U", "--arch=arm64"])
    }

    @Test func executablePathReachesNestedFamilies() {
        #expect(Simctl(executablePath: "/opt/xcrun").boot("U").command().executableName == "/opt/xcrun")
        #expect(XCResultTool(executablePath: "/opt/xcrun").testResultsSummary(path: "a").command().executableName == "/opt/xcrun")
        #expect(Agvtool(executablePath: "/opt/xcrun").whatVersionTerse().command().executableName == "/opt/xcrun")
    }
}
