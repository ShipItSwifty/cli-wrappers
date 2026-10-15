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
        let command = Adb()
            .install(apk: "app-release.apk", replace: true)
            .command()

        #expect(command.executableName == "adb")
        #expect(command.arguments.contains("install"))
        #expect(command.arguments.contains("-r"))
        #expect(command.arguments.contains("app-release.apk"))
    }

    @Test("Adb builds shell command")
    func shellCommand() {
        let command = Adb()
            .shell("am start -n com.example/.MainActivity")
            .command()

        let args = command.arguments
        #expect(args.contains("shell"))
        #expect(args.contains("am start -n com.example/.MainActivity"))
    }

    @Test("Adb devices command uses 'adb' executable")
    func devicesCommand() {
        let cmd = Adb().devices().command()
        #expect(cmd.executableName == "adb")
        #expect(cmd.arguments.contains("devices"))
    }

    @Test("Adb raw arguments preserve serial prefix")
    func rawArgumentsCommand() {
        let command = Adb()
            .serial("emulator-5554")
            .rawArguments(["version"])
            .command()

        #expect(command.executableName == "adb")
        #expect(command.arguments == ["-s", "emulator-5554", "version"])
    }

    @Test("Adb serial targets a specific device")
    func serialCommand() {
        let command = Adb()
            .serial("R5CT2074MZ")
            .devices()
            .command()

        #expect(command.arguments == ["-s", "R5CT2074MZ", "devices"])
    }

    @Test("Adb nil serial produces no prefix")
    func nilSerialCommand() {
        let command = Adb()
            .serial("emulator-5554")
            .serial(nil)
            .devices()
            .command()

        #expect(command.arguments == ["devices"])
    }

    @Test("Adb start-server command")
    func startServerCommand() {
        let command = Adb().startServer().command()
        #expect(command.arguments == ["start-server"])
    }

    @Test("Adb kill-server command")
    func killServerCommand() {
        let command = Adb().killServer().command()
        #expect(command.arguments == ["kill-server"])
    }

    @Test("Adb devices long format")
    func devicesLongCommand() {
        let command = Adb().devices(long: true).command()
        #expect(command.arguments == ["devices", "-l"])
    }

    @Test("Adb wait-for-device command")
    func waitForDeviceCommand() {
        let command = Adb().waitForDevice().command()
        #expect(command.arguments == ["wait-for-device"])
    }

    @Test("Adb uninstall command")
    func uninstallCommand() {
        let command = Adb().uninstall(package: "com.example.app").command()
        #expect(command.arguments == ["uninstall", "com.example.app"])
    }

    @Test("Adb am force-stop command")
    func amForceStopCommand() {
        let command = Adb().amForceStop(package: "com.example.app").command()
        #expect(command.arguments == ["shell", "am", "force-stop", "com.example.app"])
    }

    @Test("Adb am start activity with extras")
    func amStartActivityExtras() {
        let command = Adb()
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
        let command = Adb()
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
        let command = Adb().amStartViewURL("https://example.com").command()
        #expect(
            command.arguments == [
                "shell", "am", "start",
                "-a", "android.intent.action.VIEW",
                "-d", "https://example.com",
            ])
    }

    @Test("Adb pm list packages")
    func pmListPackages() {
        let command = Adb().pmListPackages().command()
        #expect(command.arguments == ["shell", "pm", "list", "packages"])
    }

    @Test("Adb pm grant permission")
    func pmGrantPermission() {
        let command = Adb()
            .pmGrantPermission(package: "com.example", permission: "android.permission.CAMERA")
            .command()
        #expect(
            command.arguments == [
                "shell", "pm", "grant", "com.example", "android.permission.CAMERA",
            ])
    }

    @Test("Adb pm revoke permission")
    func pmRevokePermission() {
        let command = Adb()
            .pmRevokePermission(package: "com.example", permission: "android.permission.CAMERA")
            .command()
        #expect(
            command.arguments == [
                "shell", "pm", "revoke", "com.example", "android.permission.CAMERA",
            ])
    }

    @Test("Adb resolve launchable activity")
    func resolveLaunchableActivity() {
        let command = Adb().resolveLaunchableActivity(package: "com.example").command()
        #expect(
            command.arguments == [
                "shell", "cmd", "package", "resolve-activity", "--brief", "com.example",
            ])
    }

    @Test("Adb screencap command")
    func screencapCommand() {
        let command = Adb().screencap(remotePath: "/sdcard/screen.png").command()
        #expect(command.arguments == ["shell", "screencap", "-p", "/sdcard/screen.png"])
    }

    @Test("Adb screenrecord command")
    func screenrecordCommand() {
        let command = Adb().screenrecord(remotePath: "/sdcard/demo.mp4").command()
        #expect(command.arguments == ["shell", "screenrecord", "/sdcard/demo.mp4"])
    }

    @Test("Adb shell pkill command")
    func shellPkillCommand() {
        let command = Adb().shellPkill(process: "screenrecord").command()
        #expect(command.arguments == ["shell", "pkill", "-INT", "screenrecord"])
    }

    @Test("Adb input keyevent command")
    func inputKeyeventCommand() {
        let command = Adb().inputKeyevent("KEYCODE_HOME").command()
        #expect(command.arguments == ["shell", "input", "keyevent", "KEYCODE_HOME"])
    }

    @Test("Adb uimode night command")
    func cmdUimodeNightCommand() {
        let command = Adb().cmdUimodeNight(.yes).command()
        #expect(command.arguments == ["shell", "cmd", "uimode", "night", "yes"])
    }

    @Test("Adb forward TCP command")
    func forwardTCPCommand() {
        let command = Adb().forwardTCP(localPort: 8080, remotePort: 3000).command()
        #expect(command.arguments == ["forward", "tcp:8080", "tcp:3000"])
    }

    @Test("Adb remove forward TCP command")
    func removeForwardTCPCommand() {
        let command = Adb().removeForwardTCP(localPort: 8080).command()
        #expect(command.arguments == ["forward", "--remove", "tcp:8080"])
    }

    @Test("Adb push command")
    func pushCommand() {
        let command = Adb().push(local: "./file.txt", remote: "/sdcard/file.txt").command()
        #expect(command.arguments == ["push", "./file.txt", "/sdcard/file.txt"])
    }

    @Test("Adb pull command")
    func pullCommand() {
        let command = Adb().pull(remote: "/sdcard/file.txt", local: "./file.txt").command()
        #expect(command.arguments == ["pull", "/sdcard/file.txt", "./file.txt"])
    }

    @Test("Adb logcat with filters")
    func logcatCommand() {
        let command = Adb().logcat(filters: ["*:E"]).command()
        #expect(command.arguments == ["logcat", "*:E"])
    }

    @Test("Adb emu kill command")
    func emuKillCommand() {
        let command = Adb().emuKill().command()
        #expect(command.arguments == ["emu", "kill"])
    }

    @Test("Adb emu geo fix command")
    func emuGeoFixCommand() {
        let command = Adb().emuGeoFix(longitude: -122.084, latitude: 37.422).command()
        #expect(command.arguments == ["emu", "geo", "fix", "-122.084", "37.422"])
    }
    @Test("Package path and forwarded-port inventory use typed commands")
    func pathAndForwards() {
        #expect(Adb().serial("S").pmPath(package: "com.example").command().arguments == ["-s", "S", "shell", "pm", "path", "com.example"])
        #expect(Adb().listForwards().command().arguments == ["forward", "--list"])
    }

}
