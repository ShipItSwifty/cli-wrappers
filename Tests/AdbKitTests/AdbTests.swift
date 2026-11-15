import Foundation
import SwiftyShell
import Synchronization
import Testing

@testable import AdbKit

// MARK: - Adb command builder tests

@Suite("Adb")
struct AdbTests {
    @Test("Adb builds install command")
    func installCommand() {
        let command = Adb(executablePath: "adb")
            .install(apk: "app-release.apk", replace: true)
            .command()

        #expect(command.executableName == "adb")
        #expect(command.arguments.contains("install"))
        #expect(command.arguments.contains("-r"))
        #expect(command.arguments.contains("app-release.apk"))
    }

    @Test("Adb builds shell command")
    func shellCommand() {
        let command = Adb(executablePath: "adb")
            .shell("am start -n com.example/.MainActivity")
            .command()

        let args = command.arguments
        #expect(args.contains("shell"))
        #expect(args.contains("am start -n com.example/.MainActivity"))
    }

    @Test("Adb devices command uses 'adb' executable")
    func devicesCommand() {
        let cmd = Adb(executablePath: "adb").devices().command()
        #expect(cmd.executableName == "adb")
        #expect(cmd.arguments.contains("devices"))
    }

    @Test("Adb raw arguments preserve serial prefix")
    func rawArgumentsCommand() {
        let command = Adb(executablePath: "adb")
            .serial("emulator-5554")
            .rawArguments(["version"])
            .command()

        #expect(command.executableName == "adb")
        #expect(command.arguments == ["-s", "emulator-5554", "version"])
    }

    @Test("Adb serial targets a specific device")
    func serialCommand() {
        let command = Adb(executablePath: "adb")
            .serial("R5CT2074MZ")
            .devices()
            .command()

        #expect(command.arguments == ["-s", "R5CT2074MZ", "devices"])
    }

    @Test("Adb nil serial produces no prefix")
    func nilSerialCommand() {
        let command = Adb(executablePath: "adb")
            .serial("emulator-5554")
            .serial(nil)
            .devices()
            .command()

        #expect(command.arguments == ["devices"])
    }

    @Test("Adb start-server command")
    func startServerCommand() {
        let command = Adb(executablePath: "adb").startServer().command()
        #expect(command.arguments == ["start-server"])
    }

    @Test("Adb kill-server command")
    func killServerCommand() {
        let command = Adb(executablePath: "adb").killServer().command()
        #expect(command.arguments == ["kill-server"])
    }

    @Test("Adb devices long format")
    func devicesLongCommand() {
        let command = Adb(executablePath: "adb").devices(long: true).command()
        #expect(command.arguments == ["devices", "-l"])
    }

    @Test("Adb wait-for-device command")
    func waitForDeviceCommand() {
        let command = Adb(executablePath: "adb").waitForDevice().command()
        #expect(command.arguments == ["wait-for-device"])
    }

    @Test("Adb uninstall command")
    func uninstallCommand() {
        let command = Adb(executablePath: "adb").uninstall(package: "com.example.app").command()
        #expect(command.arguments == ["uninstall", "com.example.app"])
    }

    @Test("Adb am force-stop command")
    func amForceStopCommand() {
        let command = Adb(executablePath: "adb").amForceStop(package: "com.example.app").command()
        #expect(command.arguments == ["shell", "am", "force-stop", "com.example.app"])
    }

    @Test("Adb am start activity with extras")
    func amStartActivityExtras() {
        let command = Adb(executablePath: "adb")
            .amStartActivity(
                component: "com.example/.MainActivity",
                extras: ["key1": "val1", "key2": "val2"]
            )
            .command()

        #expect(
            command.arguments == [
                "shell", "am", "start", "-n", "com.example/.MainActivity",
                "--es", "key1", "val1",
                "--es", "key2", "val2",
            ])
    }

    @Test("Adb am start activity with ordered arguments")
    func amStartActivityArguments() {
        let command = Adb(executablePath: "adb")
            .amStartActivity(component: "com.example/.Main", arguments: ["a", "b"])
            .command()

        #expect(
            command.arguments == [
                "shell", "am", "start", "-n", "com.example/.Main",
                "--es", "arg", "a",
                "--es", "arg", "b",
            ])
    }

    @Test("Adb am start VIEW URL")
    func amStartViewURL() {
        let command = Adb(executablePath: "adb").amStartViewURL("https://example.com").command()
        #expect(
            command.arguments == [
                "shell", "am", "start",
                "-a", "android.intent.action.VIEW",
                "-d", "https://example.com",
            ])
    }

    @Test("Adb pm list packages")
    func pmListPackages() {
        let command = Adb(executablePath: "adb").pmListPackages().command()
        #expect(command.arguments == ["shell", "pm", "list", "packages"])
    }

    @Test("Adb pm grant permission")
    func pmGrantPermission() {
        let command = Adb(executablePath: "adb")
            .pmGrantPermission(package: "com.example", permission: "android.permission.CAMERA")
            .command()
        #expect(
            command.arguments == [
                "shell", "pm", "grant", "com.example", "android.permission.CAMERA",
            ])
    }

    @Test("Adb pm revoke permission")
    func pmRevokePermission() {
        let command = Adb(executablePath: "adb")
            .pmRevokePermission(package: "com.example", permission: "android.permission.CAMERA")
            .command()
        #expect(
            command.arguments == [
                "shell", "pm", "revoke", "com.example", "android.permission.CAMERA",
            ])
    }

    @Test("Adb resolve launchable activity")
    func resolveLaunchableActivity() {
        let command = Adb(executablePath: "adb").resolveLaunchableActivity(package: "com.example").command()
        #expect(
            command.arguments == [
                "shell", "cmd", "package", "resolve-activity", "--brief", "com.example",
            ])
    }

    @Test("Adb screencap command")
    func screencapCommand() {
        let command = Adb(executablePath: "adb").screencap(remotePath: "/sdcard/screen.png").command()
        #expect(command.arguments == ["shell", "screencap", "-p", "/sdcard/screen.png"])
    }

    @Test("Adb screenrecord command")
    func screenrecordCommand() {
        let command = Adb(executablePath: "adb").screenrecord(remotePath: "/sdcard/demo.mp4").command()
        #expect(command.arguments == ["shell", "screenrecord", "/sdcard/demo.mp4"])
    }

    @Test("Adb shell pkill command")
    func shellPkillCommand() {
        let command = Adb(executablePath: "adb").shellPkill(process: "screenrecord").command()
        #expect(command.arguments == ["shell", "pkill", "-INT", "screenrecord"])
    }

    @Test("Adb input keyevent command")
    func inputKeyeventCommand() {
        let command = Adb(executablePath: "adb").inputKeyevent("KEYCODE_HOME").command()
        #expect(command.arguments == ["shell", "input", "keyevent", "KEYCODE_HOME"])
    }

    @Test("Adb uimode night command")
    func cmdUimodeNightCommand() {
        let command = Adb(executablePath: "adb").cmdUimodeNight(.yes).command()
        #expect(command.arguments == ["shell", "cmd", "uimode", "night", "yes"])
    }

    @Test("Adb forward TCP command")
    func forwardTCPCommand() {
        let command = Adb(executablePath: "adb").forwardTCP(localPort: 8080, remotePort: 3000).command()
        #expect(command.arguments == ["forward", "tcp:8080", "tcp:3000"])
    }

    @Test("Adb remove forward TCP command")
    func removeForwardTCPCommand() {
        let command = Adb(executablePath: "adb").removeForwardTCP(localPort: 8080).command()
        #expect(command.arguments == ["forward", "--remove", "tcp:8080"])
    }

    @Test("Adb push command")
    func pushCommand() {
        let command = Adb(executablePath: "adb").push(local: "./file.txt", remote: "/sdcard/file.txt").command()
        #expect(command.arguments == ["push", "./file.txt", "/sdcard/file.txt"])
    }

    @Test("Adb pull command")
    func pullCommand() {
        let command = Adb(executablePath: "adb").pull(remote: "/sdcard/file.txt", local: "./file.txt").command()
        #expect(command.arguments == ["pull", "/sdcard/file.txt", "./file.txt"])
    }

    @Test("Adb logcat with filters")
    func logcatCommand() {
        let command = Adb(executablePath: "adb").logcat(filters: ["*:E"]).command()
        #expect(command.arguments == ["logcat", "*:E"])
    }

    @Test("Adb emu kill command")
    func emuKillCommand() {
        let command = Adb(executablePath: "adb").emuKill().command()
        #expect(command.arguments == ["emu", "kill"])
    }

    @Test("Adb emu geo fix command")
    func emuGeoFixCommand() {
        let command = Adb(executablePath: "adb").emuGeoFix(longitude: -122.084, latitude: 37.422).command()
        #expect(command.arguments == ["emu", "geo", "fix", "-122.084", "37.422"])
    }
    @Test("Package path and forwarded-port inventory use typed commands")
    func pathAndForwards() {
        #expect(
            Adb(executablePath: "adb").serial("S").pmPath(package: "com.example").command().arguments == [
                "-s", "S", "shell", "pm", "path", "com.example",
            ])
        #expect(Adb(executablePath: "adb").listForwards().command().arguments == ["forward", "--list"])
    }

    @Test("Executable resolves from the SDK platform-tools directory, then PATH")
    func executableResolution() {
        let exists: (String) -> Bool = { $0 == "/sdk/platform-tools/adb" }
        #expect(Adb.resolveExecutable(environment: ["ANDROID_HOME": "/sdk"], fileExists: exists) == "/sdk/platform-tools/adb")
        #expect(Adb.resolveExecutable(environment: ["ANDROID_HOME": "/other"], fileExists: exists) == "adb")
        #expect(Adb(executablePath: "/custom/adb").version().command().executableName == "/custom/adb")
    }

    @Test(
        "Additional operations emit the full argv",
        arguments: [
            (Adb(executablePath: "adb").version(), ["version"]),
            (Adb(executablePath: "adb").reconnect(), ["reconnect"]),
            (Adb(executablePath: "adb").emuAVDName(), ["emu", "avd", "name"]),
            (Adb(executablePath: "adb").pmClear(package: "com.example"), ["shell", "pm", "clear", "com.example"]),
            (Adb(executablePath: "adb").removeFile(remotePath: "/sdcard/a.png"), ["shell", "rm", "/sdcard/a.png"]),
            (Adb(executablePath: "adb").removeFile(remotePath: "/sdcard/a.png", force: true), ["shell", "rm", "-f", "/sdcard/a.png"]),
            (
                Adb(executablePath: "adb").resolveActivity(package: "com.example"),
                ["shell", "cmd", "package", "resolve-activity", "--brief", "com.example"]
            ),
            (
                Adb(executablePath: "adb").resolveActivity(
                    package: "com.example", action: "android.intent.action.MAIN", category: "android.intent.category.LAUNCHER"),
                [
                    "shell", "cmd", "package", "resolve-activity", "--brief", "-a", "android.intent.action.MAIN", "-c",
                    "android.intent.category.LAUNCHER", "com.example",
                ]
            ),
            (
                Adb(executablePath: "adb").installMultiple(apks: ["a.apk", "b.apk"], replace: true, grantAllPermissions: true),
                ["install-multiple", "-r", "-g", "a.apk", "b.apk"]
            ),
            (Adb(executablePath: "adb").reverseTCP(remotePort: 8081, localPort: 8081), ["reverse", "tcp:8081", "tcp:8081"]),
            (Adb(executablePath: "adb").removeReverse(remotePort: 8081), ["reverse", "--remove", "tcp:8081"]),
            (Adb(executablePath: "adb").execOutScreencap(), ["exec-out", "screencap", "-p"]),
            (Adb(executablePath: "adb").inputTap(x: 10, y: 20), ["shell", "input", "tap", "10", "20"]),
            (Adb(executablePath: "adb").inputText("hello%sworld"), ["shell", "input", "text", "hello%sworld"]),
            (
                Adb(executablePath: "adb").inputSwipe(fromX: 1, fromY: 2, toX: 3, toY: 4, durationMilliseconds: 300),
                ["shell", "input", "swipe", "1", "2", "3", "4", "300"]
            ),
            (Adb(executablePath: "adb").inputSwipe(fromX: 1, fromY: 2, toX: 3, toY: 4), ["shell", "input", "swipe", "1", "2", "3", "4"]),
            (Adb(executablePath: "adb").logcat(clear: true), ["logcat", "-c"]),
            (Adb(executablePath: "adb").logcat(dump: true, filters: ["*:E"]), ["logcat", "-d", "*:E"]),
            (
                Adb(executablePath: "adb").amInstrument(
                    runner: "com.example.test/androidx.test.runner.AndroidJUnitRunner", raw: true,
                    arguments: ["class": "A", "annotation": "B"]),
                [
                    "shell", "am", "instrument", "-w", "-r", "-e", "annotation", "B", "-e", "class", "A",
                    "com.example.test/androidx.test.runner.AndroidJUnitRunner",
                ]
            ),
        ] as [(Adb, [String])]
    )
    func additionalOperations(adb: Adb, expected: [String]) {
        #expect(adb.command().arguments == expected)
    }

    @Test("Typed start options and extras keep their order")
    func typedStartActivity() {
        let command = Adb(executablePath: "adb")
            .serial("emulator-5554")
            .amStartActivity(
                component: "com.example/.Main", wait: true, forceStop: true, clearTop: true, user: 0,
                typedExtras: [.string("a", "1"), .bool("b", true), .int("c", 2), .long("d", 3), .float("e", 1.5), .string("a", "2")]
            )
            .command()
        #expect(
            command.arguments == [
                "-s", "emulator-5554", "shell", "am", "start", "-W", "-S", "--activity-clear-top", "--user", "0",
                "-n", "com.example/.Main", "--es", "a", "1", "--ez", "b", "true", "--ei", "c", "2", "--el", "d", "3",
                "--ef", "e", "1.5", "--es", "a", "2",
            ])
    }
}
