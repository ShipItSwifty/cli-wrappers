import Foundation
import Testing

@testable import DeviceCtlKit

/// A device name no CoreDevice knows, so a real devicectl run fails at device lookup after parsing.
private let missingDevice = "devicectl-grammar-check-no-such-device"

/// One devicectl leaf command and the wrapper call that builds it.
private struct CatalogEntry {
    /// The command path as `devicectl help` lists it.
    let leaf: String
    let ctl: DeviceCtl
    /// Whether devicectl resolves a device before doing anything, so running it against ``missingDevice`` is harmless.
    let resolvesDevice: Bool
}

private func entry(_ leaf: String, _ ctl: DeviceCtl, resolvesDevice: Bool = true) -> CatalogEntry {
    CatalogEntry(leaf: leaf, ctl: ctl, resolvesDevice: resolvesDevice)
}

/// Every leaf command of `devicectl` in Xcode 27.2 (devicectl 651.31).
private let catalog: [CatalogEntry] = {
    let d = missingDevice
    let domain = DeviceCtlFileDomain.temporary("grammar")
    return [
        entry("device appResize observe", DeviceCtl().observeAppResize(device: d)),
        entry("device appResize set", DeviceCtl().setAppResize(preferredSize: "800x600", cornerRadius: 4, device: d)),
        entry("device appResize start", DeviceCtl().startAppResize(preferredSize: "800x600", cornerRadius: 4, device: d)),
        entry(
            "device capture screen-record",
            DeviceCtl().screenRecord(
                device: d, destination: "/tmp/x.mp4", displayUniqueID: "U", codec: .hevc, maskPolicy: .black, duration: 1)),
        entry("device capture screenshot", DeviceCtl().screenshot(device: d, destination: "/tmp/x.png", displayUniqueID: "U")),
        entry(
            "device copy from",
            DeviceCtl().copyFromDevice(
                source: "a", device: d, domain: domain, destination: "/tmp/x", options: .init(user: "mobile", removeExistingContent: false))
        ),
        entry(
            "device copy to",
            DeviceCtl().copyToDevice(
                sources: ["/tmp/a", "/tmp/b"], device: d, domain: domain, destination: "x",
                options: .init(user: "mobile", removeExistingContent: true))),
        entry(
            "device info appIcon",
            DeviceCtl().appIcon(
                device: d, bundleID: "b", allowPlaceholder: true, width: 60, height: 60, scale: 2, destination: "/tmp/i.png")),
        entry("device info appResize", DeviceCtl().appResizeInfo(device: d)),
        entry("device info appearance", DeviceCtl().appearanceInfo(device: d)),
        entry(
            "device info apps",
            DeviceCtl().apps(
                device: d, bundleID: "b",
                options: .init(
                    includeAppClips: true, includeRemovableApps: false, includeDefaultApps: true, requireContainerAccess: true,
                    includeAppGroupIdentifiers: true, includeContainerPaths: true, includeAllApps: true),
                filter: .init(
                    search: "s", filter: "name = 'x'", sortBy: "Name",
                    columns: .init(columns: ["*"], hideDefaultColumns: true, hideHeaders: true)))),
        entry("device info audio", DeviceCtl().audioInfo(device: d)),
        entry("device info authListing", DeviceCtl().authListing(device: d)),
        entry("device info ddiServices", DeviceCtl().ddiServices(device: d, autoMountDDIs: false)),
        entry("device info details", DeviceCtl().details(device: d)),
        entry("device info displays", DeviceCtl().displays(device: d, stream: true)),
        entry(
            "device info files",
            DeviceCtl().files(device: d, domain: domain, username: "mobile", subdirectory: "x", recurse: false, filter: .init(search: "s"))),
        entry("device info lockState", DeviceCtl().lockState(device: d)),
        entry("device info mountpoint", DeviceCtl().mountpoint(device: d)),
        entry("device info processes", DeviceCtl().processes(device: d, filter: .init(search: "s"))),
        entry("device info standby", DeviceCtl().standbyInfo(device: d)),
        entry("device info voiceover", DeviceCtl().voiceOverInfo(device: d)),
        entry(
            "device install app",
            DeviceCtl().install(
                appPath: "/tmp/A.app", device: d, columns: .init(columns: ["*"], hideDefaultColumns: true, hideHeaders: true))),
        entry("device notification observe", DeviceCtl().observeNotifications(["a", "b"], device: d, sessionTimeout: 5)),
        entry("device notification post", DeviceCtl().postNotifications(["a", "b"], device: d)),
        entry("device orientation get", DeviceCtl().orientation(device: d)),
        entry("device orientation rotate", DeviceCtl().rotate(.left, device: d)),
        entry("device orientation set", DeviceCtl().setOrientation(.portraitUpsideDown, device: d)),
        entry("device pairings list", DeviceCtl().listPairings(device: d, filter: .init(search: "s"))),
        entry("device pairings pair", DeviceCtl().pairWatches(phone: d, watches: [d, d])),
        entry("device pairings set-active", DeviceCtl().setActivePairing(phone: d, watch: d)),
        entry("device pairings unpair", DeviceCtl().unpairWatches(phone: d, watches: [d])),
        entry(
            "device pasteboard copy",
            DeviceCtl().pasteboardCopy(device: d, type: "public.png", files: ["/tmp/a", "/tmp/b"], pasteboard: "general")),
        entry("device pasteboard info", DeviceCtl().pasteboardInfo(device: d, pasteboard: "general")),
        entry("device pasteboard monitor", DeviceCtl().pasteboardMonitor(device: d, sessionTimeout: 5, pasteboard: "general")),
        entry("device pasteboard paste", DeviceCtl().pasteboardPaste(device: d, type: "public.png", item: 0, pasteboard: "general")),
        entry(
            "device pasteboard sync-with-host",
            DeviceCtl().pasteboardSyncWithHost(
                device: d,
                options: .init(
                    sessionTimeout: 5, devicePasteboard: "general", hostPasteboard: "general", dataPolicy: .allResolved,
                    dataPolicyFromDevice: .allPromised, dataPolicyToDevice: .matchSource, dataThresholdBytes: 8))),
        entry(
            "device pasteboard transfer from",
            DeviceCtl().pasteboardTransferFromDevice(
                device: d,
                options: .init(dataPolicy: .promiseSecondary, dataThresholdBytes: 8, devicePasteboard: "general", hostPasteboard: "general")
            )),
        entry(
            "device pasteboard transfer to",
            DeviceCtl().pasteboardTransferToDevice(
                device: d,
                options: .init(dataPolicy: .thresholdData, dataThresholdBytes: 8, devicePasteboard: "general", hostPasteboard: "general"))),
        entry("device process awaitTermination", DeviceCtl().awaitTermination(pid: 1, device: d)),
        entry(
            "device process launch",
            DeviceCtl().launch(
                bundleID: "com.example", device: d, terminateExisting: true, console: true, startStopped: true, environment: ["K": "V"],
                payloadURL: "app://x",
                options: .init(user: "501", workingDirectory: "/tmp", architecture: "arm64", activate: false, display: "U"),
                arguments: ["-v", "--timeout", "x"])),
        entry(
            "device process openURL",
            DeviceCtl().openURL("myapp://x", device: d, options: .init(activate: false, terminateExisting: true, display: "U"))),
        entry("device process resume", DeviceCtl().resume(pid: 1, device: d)),
        entry("device process sendMemoryWarning", DeviceCtl().sendMemoryWarning(pid: 1, device: d)),
        entry("device process signal", DeviceCtl().signal("SIGUSR1", pid: 1, device: d)),
        entry("device process suspend", DeviceCtl().suspend(pid: 1, device: d)),
        entry("device process terminate", DeviceCtl().terminate(pid: 1, device: d, kill: true)),
        entry(
            "device profile install",
            DeviceCtl().installProfiles(["/tmp/a.mobileprovision"], device: d, type: .provisioning, replaceExisting: false)),
        entry("device profile list", DeviceCtl().listProfiles(device: d, type: .configuration, filter: .init(search: "s"))),
        entry("device profile remove", DeviceCtl().removeProfiles(["U"], device: d, type: .provisioning, forceRemoval: true)),
        entry(
            "device profile validate",
            DeviceCtl().validateProfiles(["/tmp/devicectl-grammar-check-missing.mobileprovision"], type: .provisioning),
            resolvesDevice: false),
        entry("device reboot", DeviceCtl().reboot(style: .userspace, waitForDevice: true, device: d)),
        entry("device rename", DeviceCtl().rename(to: "x", device: d)),
        entry(
            "device settings appearance",
            DeviceCtl().appearance(
                .init(
                    mode: .dark, lookAndFeel: .tinted, textSize: .accessibilityExtraLarge, largerAccessibilitySizes: true,
                    increaseContrast: true,
                    reduceMotion: true, reduceTransparency: true, showBorders: true, liquidGlassOpacity: 0.5, colorFilter: true,
                    colorFilterType: .tritanopia, colorFilterIntensity: 0.5), device: d)),
        entry("device settings audio", DeviceCtl().audio(output: "systemDefault", input: "systemDefault", volume: 10, device: d)),
        entry("device settings biometrics", DeviceCtl().biometrics(.enable, device: d)),
        entry("device settings reset", DeviceCtl().resetDevice(device: d)),
        entry("device settings standby", DeviceCtl().standby(.show, duration: 1, device: d)),
        entry("device settings voiceover", DeviceCtl().voiceOver(enabled: true, device: d)),
        entry("device simulate biometrics", DeviceCtl().simulateBiometrics(.failure, device: d)),
        entry("device simulate location clear", DeviceCtl().clearSimulatedLocation(device: d)),
        entry("device simulate location coordinate", DeviceCtl().simulateLocation(latitude: -33.86, longitude: -122.03, device: d)),
        entry("device simulate location list", DeviceCtl().listLocationScenarios(device: d)),
        entry(
            "device simulate location route",
            DeviceCtl().simulateLocationRoute(
                .waypoints(
                    [.init(latitude: -33.8, longitude: 151.2), .init(latitude: 3, longitude: -4)], pacing: .interval(seconds: 2), speed: 5),
                device: d)),
        entry("device simulate location scenario", DeviceCtl().simulateLocationScenario("City Run", device: d)),
        entry("device simulate statusBar clear", DeviceCtl().clearStatusBar(device: d)),
        entry(
            "device simulate statusBar override",
            DeviceCtl().overrideStatusBar(
                .init(
                    time: "9:41", dataNetwork: .fiveGUWB, wifiMode: .active, wifiStrength: 3, cellularMode: .active, cellularStrength: 5,
                    batteryState: .charging, batteryLevel: 80, batteryFailingToCharge: true), device: d)),
        entry("device simulate statusBar preset", DeviceCtl().applyStatusBarPreset(.noService, device: d)),
        entry("device simulate statusBar show", DeviceCtl().showStatusBar(device: d)),
        entry("device sysdiagnose", DeviceCtl().sysdiagnose(device: d, destination: "/tmp/x", gatherFullLogs: true, dryRunOnly: true)),
        entry("device uninstall app", DeviceCtl().uninstall(bundleID: "com.example", device: d)),
        entry("list audioDevices", DeviceCtl().listAudioDevices(), resolvesDevice: false),
        entry(
            "list devices",
            DeviceCtl().listDevices(
                filter: .init(search: "zzz-no-match", sortBy: "Name", columns: .init(columns: ["*"], hideHeaders: true))),
            resolvesDevice: false),
        entry("list plugins", DeviceCtl().listPlugins(), resolvesDevice: false),
        entry("list preferredDDI", DeviceCtl().listPreferredDDI(platform: "iOS"), resolvesDevice: false),
        entry("manage ddis clean", DeviceCtl().manageDDIsClean(), resolvesDevice: false),
        entry(
            "manage ddis update",
            DeviceCtl().manageDDIsUpdate(sourceDirectories: ["/tmp"], clean: false, includeCoreDevice: false, includeXcode: false),
            resolvesDevice: false),
        entry("manage loggingProfile register", DeviceCtl().registerLoggingProfile(), resolvesDevice: false),
        entry(
            "manage pair", DeviceCtl().pairDevice(device: d, columns: .init(columns: ["*"], hideDefaultColumns: true, hideHeaders: true))),
        entry(
            "manage unpair",
            DeviceCtl().unpairDevice(device: d, columns: .init(columns: ["*"], hideDefaultColumns: true, hideHeaders: true))),
        entry(
            "diagnose",
            DeviceCtl().diagnose(
                finder: false, keepTempDirectory: true, archiveDestination: "/tmp/x.zip", archive: false, includeHostSysdiagnose: false),
            resolvesDevice: false),
    ]
}()

/// Commands that change the host or run for a long time even without a device, so the real-tool
/// run skips them. Their argv is covered by the unit tests.
private let neverRunLeaves: Set<String> = ["manage ddis clean", "manage ddis update", "manage loggingProfile register", "diagnose"]

/// The leaf commands in `devicectl help` for Xcode 27.2, kept as a literal so a typo in the
/// catalogue or a command missing from the wrapper fails a test that needs no Xcode.
private let knownLeaves: Set<String> = [
    "device appResize observe", "device appResize set", "device appResize start", "device capture screen-record",
    "device capture screenshot", "device copy from", "device copy to", "device info appIcon", "device info appResize",
    "device info appearance", "device info apps", "device info audio", "device info authListing", "device info ddiServices",
    "device info details", "device info displays", "device info files", "device info lockState", "device info mountpoint",
    "device info processes", "device info standby", "device info voiceover", "device install app", "device notification observe",
    "device notification post", "device orientation get", "device orientation rotate", "device orientation set",
    "device pairings list", "device pairings pair", "device pairings set-active", "device pairings unpair", "device pasteboard copy",
    "device pasteboard info", "device pasteboard monitor", "device pasteboard paste", "device pasteboard sync-with-host",
    "device pasteboard transfer from", "device pasteboard transfer to", "device process awaitTermination", "device process launch",
    "device process openURL", "device process resume", "device process sendMemoryWarning", "device process signal",
    "device process suspend", "device process terminate", "device profile install", "device profile list", "device profile remove",
    "device profile validate", "device reboot", "device rename", "device settings appearance", "device settings audio",
    "device settings biometrics", "device settings reset", "device settings standby", "device settings voiceover",
    "device simulate biometrics", "device simulate location clear", "device simulate location coordinate",
    "device simulate location list", "device simulate location route", "device simulate location scenario",
    "device simulate statusBar clear", "device simulate statusBar override", "device simulate statusBar preset",
    "device simulate statusBar show", "device sysdiagnose", "device uninstall app", "list audioDevices", "list devices", "list plugins",
    "list preferredDDI", "manage ddis clean", "manage ddis update", "manage loggingProfile register", "manage pair", "manage unpair",
    "diagnose",
]

@Suite("DeviceCtl command catalog")
struct DeviceCtlCatalogTests {
    @Test("The wrapper models every devicectl leaf command exactly once")
    func coversEveryLeaf() {
        let leaves = catalog.map(\.leaf)
        #expect(Set(leaves) == knownLeaves)
        #expect(leaves.count == knownLeaves.count)
        #expect(knownLeaves.count == 81)
    }

    @Test("Each wrapper call starts with its leaf command path")
    func argvStartsWithLeaf() {
        for entry in catalog {
            let path = entry.leaf.split(separator: " ").map(String.init)
            let arguments = entry.ctl.command().arguments
            #expect(Array(arguments.dropFirst().prefix(path.count)) == path, "\(entry.leaf)")
        }
    }

    @Test(
        "Real devicectl parses every device-addressed command and fails only at device lookup",
        .enabled(if: ProcessInfo.processInfo.environment["DEVICECTL_GRAMMAR_TESTS"] != nil))
    func realToolAcceptsGrammar() throws {
        for entry in catalog where (entry.resolvesDevice || entry.leaf == "device profile validate") && !neverRunLeaves.contains(entry.leaf)
        {
            let result = try run(entry.ctl.deviceTimeout(seconds: 20))
            let output = result.stdout + result.stderr
            #expect(result.status != 0, "\(entry.leaf) unexpectedly succeeded")
            let usageError = output.contains("Usage:") || output.contains("Error: ") && output.contains("Help:")
            #expect(!usageError, "\(entry.leaf) was rejected as a usage error: \(output)")
            #expect(
                output.contains("not found") || output.contains("No such file") || output.contains("does not exist")
                    || output.contains("error 1000"),
                "\(entry.leaf) did not fail at lookup: \(output)")
        }
    }

    @Test(
        "Real devicectl parses the host commands that are safe to run",
        .enabled(if: ProcessInfo.processInfo.environment["DEVICECTL_GRAMMAR_TESTS"] != nil))
    func realToolAcceptsHostGrammar() throws {
        for entry in catalog where !entry.resolvesDevice && !neverRunLeaves.contains(entry.leaf) && entry.leaf.hasPrefix("list ") {
            let result = try run(entry.ctl.deviceTimeout(seconds: 30))
            #expect(result.status == 0, "\(entry.leaf) failed: \(result.stdout + result.stderr)")
        }
    }

    private func run(_ ctl: DeviceCtl) throws -> (status: Int32, stdout: String, stderr: String) {
        let command = ctl.command()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = command.arguments
        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err
        try process.run()
        let stdoutData = out.fileHandleForReading.readDataToEndOfFile()
        let stderrData = err.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: stdoutData, as: UTF8.self), String(decoding: stderrData, as: UTF8.self))
    }
}
