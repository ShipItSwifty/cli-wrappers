import Testing

@testable import DeviceCtlKit

/// The argv after `xcrun devicectl`.
private func argv(_ ctl: DeviceCtl) -> [String] {
    Array(ctl.command().arguments.dropFirst())
}

@Suite("DeviceCtl core")
struct DeviceCtlTests {
    @Test("Runs through xcrun and appends global options after the operation")
    func listDevicesWithJSONOutput() {
        let command = DeviceCtl().listDevices().jsonOutput().deviceTimeout(seconds: 20).command()
        #expect(command.executableName == "xcrun")
        #expect(command.arguments == ["devicectl", "list", "devices", "--json-output", "-", "--timeout", "20"])
    }

    @Test("Every global option renders after the operation")
    func globalOptions() {
        let arguments = argv(
            DeviceCtl().details(device: "D").jsonOutput("/tmp/o.json").deviceTimeout(seconds: 5).quiet().verbose()
                .omitDeprecatedFieldsInJSON().logOutput("/tmp/l.log"))
        #expect(
            arguments == [
                "device", "info", "details", "--device", "D", "--json-output", "/tmp/o.json", "--timeout", "5", "--quiet", "--verbose",
                "--omit-deprecated-fields-in-json", "--log-output", "/tmp/l.log",
            ])
    }

    @Test("Launch keeps options before the bundle id and ends them with -- before app arguments")
    func launchOrdering() {
        let arguments = DeviceCtl()
            .launch(
                bundleID: "com.example", device: "D", terminateExisting: true, environment: ["B": "2", "A": "1"], arguments: ["-flag"]
            )
            .jsonOutput("/tmp/out.json")
            .command()
            .arguments
        #expect(
            arguments == [
                "devicectl", "device", "process", "launch", "--device", "D", "--terminate-existing",
                "--environment-variables", #"{"A":"1","B":"2"}"#, "--json-output", "/tmp/out.json", "--", "com.example", "-flag",
            ])
    }

    @Test("Launch without app arguments needs no terminator")
    func launchWithoutArguments() {
        #expect(
            argv(DeviceCtl().launch(bundleID: "com.example", device: "D"))
                == ["device", "process", "launch", "--device", "D", "com.example"])
    }

    @Test("Launch renders every option")
    func launchAllOptions() {
        let ctl = DeviceCtl().launch(
            bundleID: "com.example", device: "D", terminateExisting: true, console: true, startStopped: true,
            environment: ["K": "V"], payloadURL: "app://x",
            options: .init(
                user: "501", workingDirectory: "/tmp", architecture: "arm64", activate: false, display: "DISP",
                launchPersistentIdentifier: "AAAA"),
            arguments: ["--verbose", "x"])
        #expect(
            argv(ctl) == [
                "device", "process", "launch", "--device", "D", "--user", "501", "--working-directory", "/tmp", "--arch", "arm64",
                "--no-activate", "--display", "DISP", "--launch-persistent-identifier", "AAAA", "--terminate-existing", "--console",
                "--start-stopped", "--environment-variables", #"{"K":"V"}"#, "--payload-url", "app://x", "--", "com.example",
                "--verbose", "x",
            ])
    }

    @Test("Selecting a new operation drops the previous launch positionals and terminator")
    func operationResetsTrailing() {
        let arguments = DeviceCtl().launch(bundleID: "b", device: "D", arguments: ["-v"]).listDevices().command().arguments
        #expect(arguments == ["devicectl", "list", "devices"])
    }

    @Test("A raw subcommand is passed through")
    func customOperation() {
        #expect(
            argv(DeviceCtl().custom(["device", "future", "--device", "D"]).quiet()) == ["device", "future", "--device", "D", "--quiet"])
    }
}

@Suite("DeviceCtl device info")
struct DeviceCtlInfoTests {
    @Test("Info readers emit the documented grammar")
    func readers() {
        #expect(argv(DeviceCtl().details(device: "D")) == ["device", "info", "details", "--device", "D"])
        #expect(argv(DeviceCtl().processes(device: "D")) == ["device", "info", "processes", "--device", "D"])
        #expect(argv(DeviceCtl().displays(device: "D")) == ["device", "info", "displays", "--device", "D"])
        #expect(argv(DeviceCtl().displays(device: "D", stream: true)) == ["device", "info", "displays", "--device", "D", "--stream"])
        #expect(argv(DeviceCtl().appearanceInfo(device: "D")) == ["device", "info", "appearance", "--device", "D"])
        #expect(argv(DeviceCtl().audioInfo(device: "D")) == ["device", "info", "audio", "--device", "D"])
        #expect(argv(DeviceCtl().authListing(device: "D")) == ["device", "info", "authListing", "--device", "D"])
        #expect(argv(DeviceCtl().lockState(device: "D")) == ["device", "info", "lockState", "--device", "D"])
        #expect(argv(DeviceCtl().mountpoint(device: "D")) == ["device", "info", "mountpoint", "--device", "D"])
        #expect(argv(DeviceCtl().standbyInfo(device: "D")) == ["device", "info", "standby", "--device", "D"])
        #expect(argv(DeviceCtl().voiceOverInfo(device: "D")) == ["device", "info", "voiceover", "--device", "D"])
        #expect(argv(DeviceCtl().appResizeInfo(device: "D")) == ["device", "info", "appResize", "--device", "D"])
    }

    @Test("Apps renders its filters, bundle id, and table options")
    func apps() {
        #expect(argv(DeviceCtl().apps(device: "D", bundleID: "b")) == ["device", "info", "apps", "--device", "D", "--bundle-id", "b"])
        let ctl = DeviceCtl().apps(
            device: "D", bundleID: "b",
            options: .init(
                includeAppClips: true, includeRemovableApps: false, includeDefaultApps: true, requireContainerAccess: true,
                includeAppGroupIdentifiers: true, includeContainerPaths: true, includeAllApps: true),
            filter: .init(
                search: "jot", filter: "name CONTAINS 'x'", sortBy: "Name",
                columns: .init(columns: ["a", "b"], hideDefaultColumns: true, hideHeaders: true)))
        #expect(
            argv(ctl) == [
                "device", "info", "apps", "--device", "D", "--include-app-clips", "--no-include-removable-apps", "--include-default-apps",
                "--require-container-access", "--include-app-group-identifiers", "--include-container-paths", "--include-all-apps",
                "--bundle-id", "b", "--search", "jot", "--filter", "name CONTAINS 'x'", "--sort-by", "Name", "--columns", "a", "--columns",
                "b", "--hide-default-columns", "--hide-headers",
            ])
    }

    @Test("Files carry a domain and optional scoping")
    func files() {
        #expect(
            argv(DeviceCtl().files(device: "D", domain: .appData(bundleID: "com.x")))
                == ["device", "info", "files", "--device", "D", "--domain-type", "appDataContainer", "--domain-identifier", "com.x"])
        #expect(
            argv(
                DeviceCtl().files(
                    device: "D", domain: .crashLogs, username: "mobile", subdirectory: "Retired", recurse: false,
                    filter: .init(search: "ips")))
                == [
                    "device", "info", "files", "--device", "D", "--domain-type", "systemCrashLogs", "--username", "mobile",
                    "--subdirectory", "Retired", "--no-recurse", "--search", "ips",
                ])
    }

    @Test("App icon renders every parameter")
    func appIcon() {
        #expect(
            argv(
                DeviceCtl().appIcon(
                    device: "D", bundleID: "b", allowPlaceholder: true, width: 60, height: 60, scale: 2, destination: "/i.png"))
                == [
                    "device", "info", "appIcon", "--device", "D", "--app-bundle-id", "b", "--allow-placeholder", "true", "--width", "60.0",
                    "--height", "60.0", "--scale", "2.0", "--destination", "/i.png",
                ])
        #expect(
            argv(DeviceCtl().appIcon(device: "D", appPath: "/a.app"))
                == ["device", "info", "appIcon", "--device", "D", "--app-path", "/a.app"])
    }

    @Test("DDI services toggles auto-mounting")
    func ddiServices() {
        #expect(argv(DeviceCtl().ddiServices(device: "D")) == ["device", "info", "ddiServices", "--device", "D"])
        #expect(
            argv(DeviceCtl().ddiServices(device: "D", autoMountDDIs: false))
                == ["device", "info", "ddiServices", "--device", "D", "--no-auto-mount-ddis"])
    }
}

@Suite("DeviceCtl apps and processes")
struct DeviceCtlAppTests {
    @Test("Install and uninstall put the positional last")
    func installUninstall() {
        #expect(argv(DeviceCtl().install(appPath: "A.app", device: "D")) == ["device", "install", "app", "--device", "D", "A.app"])
        #expect(
            argv(DeviceCtl().install(appPath: "A.app", device: "D", columns: .init(columns: ["*"])).jsonOutput())
                == ["device", "install", "app", "--device", "D", "--columns", "*", "--json-output", "-", "A.app"])
        #expect(argv(DeviceCtl().uninstall(bundleID: "b", device: "D")) == ["device", "uninstall", "app", "--device", "D", "b"])
    }

    @Test("Process control targets a pid")
    func processControl() {
        #expect(
            argv(DeviceCtl().signal("SIGKILL", pid: 42, device: "D"))
                == ["device", "process", "signal", "--device", "D", "--pid", "42", "--signal", "SIGKILL"])
        #expect(argv(DeviceCtl().terminate(pid: 7, device: "D")) == ["device", "process", "terminate", "--device", "D", "--pid", "7"])
        #expect(
            argv(DeviceCtl().terminate(pid: 7, device: "D", kill: true))
                == ["device", "process", "terminate", "--device", "D", "--pid", "7", "--kill"])
        #expect(argv(DeviceCtl().suspend(pid: 7, device: "D")) == ["device", "process", "suspend", "--device", "D", "--pid", "7"])
        #expect(argv(DeviceCtl().resume(pid: 7, device: "D")) == ["device", "process", "resume", "--device", "D", "--pid", "7"])
        #expect(
            argv(DeviceCtl().sendMemoryWarning(pid: 7, device: "D"))
                == ["device", "process", "sendMemoryWarning", "--device", "D", "--pid", "7"])
        #expect(
            argv(DeviceCtl().awaitTermination(pid: 7, device: "D"))
                == ["device", "process", "awaitTermination", "--device", "D", "--pid", "7"])
    }

    @Test("Open URL passes the URL after its options")
    func openURL() {
        #expect(argv(DeviceCtl().openURL("myapp://x", device: "D")) == ["device", "process", "openURL", "--device", "D", "myapp://x"])
        #expect(
            argv(DeviceCtl().openURL("https://a.b", device: "D", options: .init(activate: true, terminateExisting: true, display: "X")))
                == [
                    "device", "process", "openURL", "--device", "D", "--activate", "--terminate-existing", "--display", "X", "https://a.b",
                ])
    }
}

@Suite("DeviceCtl files and capture")
struct DeviceCtlFileTests {
    @Test("Copy to repeats --source and carries the domain")
    func copyTo() {
        #expect(
            argv(
                DeviceCtl().copyToDevice(
                    sources: ["/a", "/b"], device: "D", domain: .appData(bundleID: "com.x"), destination: "Documents",
                    options: .init(user: "mobile", removeExistingContent: true)))
                == [
                    "device", "copy", "to", "--device", "D", "--source", "/a", "--source", "/b", "--domain-type", "appDataContainer",
                    "--domain-identifier", "com.x", "--destination", "Documents", "--user", "mobile", "--remove-existing-content", "true",
                ])
    }

    @Test("Copy from takes one source")
    func copyFrom() {
        #expect(
            argv(DeviceCtl().copyFromDevice(source: "log.txt", device: "D", domain: .temporary("scratch"), destination: "/out"))
                == [
                    "device", "copy", "from", "--device", "D", "--source", "log.txt", "--domain-type", "temporary", "--domain-identifier",
                    "scratch", "--destination", "/out",
                ])
        #expect(
            argv(
                DeviceCtl().copyFromDevice(
                    source: "x", device: "D", domain: .appGroup("group.x"), options: .init(removeExistingContent: false)))
                == [
                    "device", "copy", "from", "--device", "D", "--source", "x", "--domain-type", "appGroupDataContainer",
                    "--domain-identifier", "group.x", "--remove-existing-content", "false",
                ])
    }

    @Test("Capture commands emit destination and display")
    func capture() {
        #expect(
            argv(DeviceCtl().screenshot(device: "D", destination: "/s.png"))
                == ["device", "capture", "screenshot", "--device", "D", "--destination", "/s.png"])
        #expect(
            argv(DeviceCtl().screenshot(device: "D", destination: "/s.png", displayUniqueID: "U"))
                == ["device", "capture", "screenshot", "--device", "D", "--destination", "/s.png", "--display-unique-id", "U"])
        #expect(
            argv(DeviceCtl().screenRecord(device: "D", destination: "/r.mp4"))
                == ["device", "capture", "screen-record", "--device", "D", "--destination", "/r.mp4"])
        #expect(
            argv(
                DeviceCtl().screenRecord(
                    device: "D", destination: "/r.mp4", displayUniqueID: "U", codec: .hevc, maskPolicy: .premultipliedAlpha, duration: 5))
                == [
                    "device", "capture", "screen-record", "--device", "D", "--destination", "/r.mp4", "--display-unique-id", "U",
                    "--codec", "hevc", "--mask-policy", "premultipliedAlpha", "--duration", "5.0",
                ])
    }
}

@Suite("DeviceCtl settings and simulation")
struct DeviceCtlSettingsTests {
    @Test("Appearance keeps the mode shorthand and renders every setting")
    func appearance() {
        #expect(
            argv(DeviceCtl().appearance(.dark, device: "D")) == ["device", "settings", "appearance", "--device", "D", "--mode", "dark"])
        let settings = DeviceCtlAppearanceSettings(
            mode: .light, lookAndFeel: .tinted, textSize: .accessibilityLarge, largerAccessibilitySizes: true, increaseContrast: false,
            reduceMotion: true, reduceTransparency: false, showBorders: true, liquidGlassOpacity: 0.5, colorFilter: true,
            colorFilterType: .deuteranopia, colorFilterIntensity: 0.75)
        #expect(
            argv(DeviceCtl().appearance(settings, device: "D")) == [
                "device", "settings", "appearance", "--device", "D", "--mode", "light", "--look-and-feel", "tinted", "--text-size",
                "accessibility-large", "--larger-accessibility-sizes", "on", "--increase-contrast", "off", "--reduce-motion", "on",
                "--reduce-transparency", "off", "--show-borders", "on", "--liquid-glass-opacity", "0.5", "--color-filter", "on",
                "--color-filter-type", "deuteranopia", "--color-filter-intensity", "0.75",
            ])
    }

    @Test("Audio, biometrics, StandBy, and VoiceOver settings")
    func settings() {
        #expect(
            argv(DeviceCtl().audio(output: "systemDefault", input: "UID", volume: 40, device: "D"))
                == [
                    "device", "settings", "audio", "--device", "D", "--output-device", "systemDefault", "--input-device", "UID",
                    "--volume", "40",
                ])
        #expect(argv(DeviceCtl().biometrics(device: "D")) == ["device", "settings", "biometrics", "--device", "D"])
        #expect(argv(DeviceCtl().biometrics(.enable, device: "D")) == ["device", "settings", "biometrics", "--device", "D", "--enable"])
        #expect(argv(DeviceCtl().biometrics(.disable, device: "D")) == ["device", "settings", "biometrics", "--device", "D", "--disable"])
        #expect(argv(DeviceCtl().standby(.show, device: "D")) == ["device", "settings", "standby", "--device", "D", "--show"])
        #expect(
            argv(DeviceCtl().standby(.hide, duration: 3, device: "D"))
                == ["device", "settings", "standby", "--device", "D", "--hide", "--duration", "3.0"])
        #expect(
            argv(DeviceCtl().voiceOver(enabled: true, device: "D")) == ["device", "settings", "voiceover", "--device", "D", "--enable"])
        #expect(
            argv(DeviceCtl().voiceOver(enabled: false, device: "D")) == ["device", "settings", "voiceover", "--device", "D", "--disable"])
        #expect(argv(DeviceCtl().resetDevice(device: "D")) == ["device", "settings", "reset", "--device", "D"])
    }

    @Test("Orientation and resizable sessions")
    func orientationAndResize() {
        #expect(argv(DeviceCtl().orientation(device: "D")) == ["device", "orientation", "get", "--device", "D"])
        #expect(
            argv(DeviceCtl().setOrientation(.landscapeLeft, device: "D"))
                == ["device", "orientation", "set", "--device", "D", "landscapeLeft"])
        #expect(argv(DeviceCtl().rotate(.right, device: "D")) == ["device", "orientation", "rotate", "--device", "D", "right"])
        #expect(argv(DeviceCtl().observeAppResize(device: "D")) == ["device", "appResize", "observe", "--device", "D"])
        #expect(
            argv(DeviceCtl().setAppResize(preferredSize: "800x600", cornerRadius: 12, device: "D"))
                == ["device", "appResize", "set", "--device", "D", "--preferred-size", "800x600", "--corner-radius", "12.0"])
        #expect(argv(DeviceCtl().startAppResize(device: "D")) == ["device", "appResize", "start", "--device", "D"])
        #expect(
            argv(DeviceCtl().startAppResize(preferredSize: "1x1", device: "D"))
                == ["device", "appResize", "start", "--device", "D", "--preferred-size", "1x1"])
    }

    @Test("Device actions")
    func deviceActions() {
        #expect(argv(DeviceCtl().reboot(device: "D")) == ["device", "reboot", "--device", "D"])
        #expect(
            argv(DeviceCtl().reboot(style: .userspace, waitForDevice: true, device: "D"))
                == ["device", "reboot", "--device", "D", "--style", "userspace", "--wait-for-device"])
        #expect(argv(DeviceCtl().rename(to: "Lab", device: "D")) == ["device", "rename", "--device", "D", "--name", "Lab"])
        #expect(argv(DeviceCtl().sysdiagnose(device: "D")) == ["device", "sysdiagnose", "--device", "D"])
        #expect(
            argv(DeviceCtl().sysdiagnose(device: "D", destination: "/d", gatherFullLogs: true, dryRunOnly: true))
                == ["device", "sysdiagnose", "--device", "D", "--destination", "/d", "--gather-full-logs", "--dry-run-only"])
    }

    @Test("Location simulation")
    func location() {
        #expect(
            argv(DeviceCtl().simulateLocation(latitude: 1.5, longitude: -2, device: "D"))
                == ["device", "simulate", "location", "coordinate", "--device", "D", "--latitude=1.5", "--longitude=-2.0"])
        #expect(argv(DeviceCtl().clearSimulatedLocation(device: "D")) == ["device", "simulate", "location", "clear", "--device", "D"])
        #expect(argv(DeviceCtl().listLocationScenarios(device: "D")) == ["device", "simulate", "location", "list", "--device", "D"])
        #expect(
            argv(DeviceCtl().simulateLocationScenario("City Run", device: "D"))
                == ["device", "simulate", "location", "scenario", "--device", "D", "City Run"])
        #expect(
            argv(DeviceCtl().simulateLocationRoute(.file("/r.json"), device: "D"))
                == ["device", "simulate", "location", "route", "--device", "D", "--route-file", "/r.json"])
        let route = DeviceCtlLocationRoute.waypoints(
            [.init(latitude: 37.5, longitude: -122.5), .init(latitude: 40, longitude: -74)], pacing: .distance(meters: 100), speed: 5)
        #expect(
            argv(DeviceCtl().simulateLocationRoute(route, device: "D")) == [
                "device", "simulate", "location", "route", "--device", "D", "--mode", "distance", "--distance", "100.0", "--speed", "5.0",
                "--waypoints", "37.5,-122.5", "40.0,-74.0",
            ])
        let interval = DeviceCtlLocationRoute.waypoints([.init(latitude: 1, longitude: 2)], pacing: .interval(seconds: 2), speed: nil)
        #expect(
            argv(DeviceCtl().simulateLocationRoute(interval, device: "D")) == [
                "device", "simulate", "location", "route", "--device", "D", "--mode", "interval", "--interval", "2.0", "--waypoints",
                "1.0,2.0",
            ])
    }

    @Test("Status bar and biometric simulation")
    func statusBarAndBiometrics() {
        #expect(argv(DeviceCtl().showStatusBar(device: "D")) == ["device", "simulate", "statusBar", "show", "--device", "D"])
        #expect(argv(DeviceCtl().clearStatusBar(device: "D")) == ["device", "simulate", "statusBar", "clear", "--device", "D"])
        #expect(
            argv(DeviceCtl().applyStatusBarPreset(.lowBattery, device: "D"))
                == ["device", "simulate", "statusBar", "preset", "--device", "D", "low-battery"])
        let override = DeviceCtlStatusBarOverride(
            time: "9:41", dataNetwork: .fiveGUWB, wifiMode: .active, wifiStrength: 3, cellularMode: .active, cellularStrength: 5,
            batteryState: .charging, batteryLevel: 80, batteryFailingToCharge: true)
        #expect(
            argv(DeviceCtl().overrideStatusBar(override, device: "D")) == [
                "device", "simulate", "statusBar", "override", "--device", "D", "--time", "9:41", "--data-network", "5GUWB", "--wifi-mode",
                "active", "--wifi-strength", "3", "--cellular-mode", "active", "--cellular-strength", "5", "--battery-state", "charging",
                "--battery-level", "80", "--battery-failing-to-charge",
            ])
        #expect(
            argv(DeviceCtl().simulateBiometrics(.success, device: "D")) == [
                "device", "simulate", "biometrics", "--device", "D", "--success",
            ])
        #expect(
            argv(DeviceCtl().simulateBiometrics(.failure, device: "D")) == [
                "device", "simulate", "biometrics", "--device", "D", "--failure",
            ])
    }
}

@Suite("DeviceCtl pasteboard and notifications")
struct DeviceCtlPasteboardTests {
    @Test("Pasteboard copy, paste, info, and monitor")
    func basics() {
        #expect(argv(DeviceCtl().pasteboardCopy(device: "D")) == ["device", "pasteboard", "copy", "--device", "D"])
        #expect(
            argv(DeviceCtl().pasteboardCopy(device: "D", type: "public.png", files: ["a.png", "b.png"], pasteboard: "p"))
                == [
                    "device", "pasteboard", "copy", "--device", "D", "--type", "public.png", "--file", "a.png", "--file", "b.png",
                    "--device-pasteboard", "p",
                ])
        #expect(
            argv(DeviceCtl().pasteboardPaste(device: "D", type: "public.png", item: 1, pasteboard: "p").jsonOutput("/o.json"))
                == [
                    "device", "pasteboard", "paste", "--device", "D", "--type", "public.png", "--item", "1", "--device-pasteboard", "p",
                    "--json-output", "/o.json",
                ])
        #expect(
            argv(DeviceCtl().pasteboardInfo(device: "D", pasteboard: "p")) == [
                "device", "pasteboard", "info", "--device", "D", "--device-pasteboard", "p",
            ])
        #expect(
            argv(DeviceCtl().pasteboardMonitor(device: "D", sessionTimeout: 30))
                == ["device", "pasteboard", "monitor", "--device", "D", "--session-timeout", "30"])
    }

    @Test("Pasteboard transfers and sync render data policy options")
    func transfers() {
        let transfer = DeviceCtlPasteboardTransfer(
            dataPolicy: .thresholdData, dataThresholdBytes: 1024, devicePasteboard: "dp", hostPasteboard: "hp")
        let expected = [
            "--data-policy", "threshold-data", "--data-threshold-bytes", "1024", "--device-pasteboard", "dp", "--host-pasteboard", "hp",
        ]
        #expect(
            argv(DeviceCtl().pasteboardTransferToDevice(device: "D", options: transfer)) == [
                "device", "pasteboard", "transfer", "to", "--device", "D",
            ] + expected)
        #expect(
            argv(DeviceCtl().pasteboardTransferFromDevice(device: "D", options: transfer)) == [
                "device", "pasteboard", "transfer", "from", "--device", "D",
            ] + expected)
        #expect(argv(DeviceCtl().pasteboardTransferToDevice(device: "D")) == ["device", "pasteboard", "transfer", "to", "--device", "D"])
        let sync = DeviceCtlPasteboardSync(
            sessionTimeout: 60, devicePasteboard: "dp", hostPasteboard: "hp", dataPolicy: .allResolved,
            dataPolicyFromDevice: .allPromised, dataPolicyToDevice: .matchSource, dataThresholdBytes: 8)
        #expect(
            argv(DeviceCtl().pasteboardSyncWithHost(device: "D", options: sync)) == [
                "device", "pasteboard", "sync-with-host", "--device", "D", "--session-timeout", "60", "--device-pasteboard", "dp",
                "--host-pasteboard", "hp", "--data-policy", "all-resolved", "--data-policy-from-device", "all-promised",
                "--data-policy-to-device", "match-source", "--data-threshold-bytes", "8",
            ])
    }

    @Test("Darwin notifications repeat --name")
    func notifications() {
        #expect(
            argv(DeviceCtl().postNotifications(["a", "b"], device: "D"))
                == ["device", "notification", "post", "--device", "D", "--name", "a", "--name", "b"])
        #expect(
            argv(DeviceCtl().observeNotifications(["a"], device: "D", sessionTimeout: 10))
                == ["device", "notification", "observe", "--device", "D", "--name", "a", "--session-timeout", "10"])
    }
}

@Suite("DeviceCtl profiles, pairings, and host")
struct DeviceCtlHostTests {
    @Test("Profile commands put identifiers and paths last")
    func profiles() {
        #expect(
            argv(
                DeviceCtl().installProfiles(
                    ["a.mobileprovision", "b.mobileconfig"], device: "D", type: .provisioning, replaceExisting: false))
                == [
                    "device", "profile", "install", "--device", "D", "--type", "provisioning", "--no-replace-existing", "a.mobileprovision",
                    "b.mobileconfig",
                ])
        #expect(
            argv(DeviceCtl().listProfiles(device: "D", type: .configuration, filter: .init(search: "x")))
                == ["device", "profile", "list", "--device", "D", "--type", "configuration", "--search", "x"])
        #expect(
            argv(DeviceCtl().removeProfiles(["U1", "U2"], device: "D", type: .provisioning, forceRemoval: true))
                == ["device", "profile", "remove", "--device", "D", "--type", "provisioning", "--force-removal", "U1", "U2"])
        #expect(argv(DeviceCtl().validateProfiles(["p.mobileprovision"])) == ["device", "profile", "validate", "p.mobileprovision"])
        #expect(
            argv(DeviceCtl().validateProfiles(["p"], type: .configuration))
                == ["device", "profile", "validate", "--type", "configuration", "p"])
    }

    @Test("Pairing commands name the phone and watches")
    func pairings() {
        #expect(argv(DeviceCtl().listPairings(device: "D")) == ["device", "pairings", "list", "--device", "D"])
        #expect(
            argv(DeviceCtl().pairWatches(phone: "P", watches: ["W1", "W2"]))
                == ["device", "pairings", "pair", "--phone", "P", "--watch", "W1", "--watch", "W2"])
        #expect(
            argv(DeviceCtl().setActivePairing(phone: "P", watch: "W"))
                == ["device", "pairings", "set-active", "--phone", "P", "--watch", "W"])
        #expect(
            argv(DeviceCtl().unpairWatches(phone: "P", watches: ["W"]))
                == ["device", "pairings", "unpair", "--phone", "P", "--watch", "W"])
    }

    @Test("List commands")
    func lists() {
        #expect(argv(DeviceCtl().listAudioDevices()) == ["list", "audioDevices"])
        #expect(argv(DeviceCtl().listPlugins()) == ["list", "plugins"])
        #expect(argv(DeviceCtl().listPreferredDDI()) == ["list", "preferredDDI"])
        #expect(argv(DeviceCtl().listPreferredDDI(platform: "iOS")) == ["list", "preferredDDI", "--platform", "iOS"])
        #expect(
            argv(DeviceCtl().listDevices(filter: .init(search: "iPhone", sortBy: "Name")))
                == ["list", "devices", "--search", "iPhone", "--sort-by", "Name"])
    }

    @Test("Manage and diagnose commands")
    func manage() {
        #expect(argv(DeviceCtl().manageDDIsClean()) == ["manage", "ddis", "clean"])
        #expect(argv(DeviceCtl().manageDDIsUpdate()) == ["manage", "ddis", "update"])
        #expect(
            argv(DeviceCtl().manageDDIsUpdate(sourceDirectories: ["/a", "/b"], clean: true, includeCoreDevice: false, includeXcode: false))
                == [
                    "manage", "ddis", "update", "--source-dir", "/a", "--source-dir", "/b", "--clean", "--no-include-coredevice",
                    "--no-include-xcode",
                ])
        #expect(argv(DeviceCtl().registerLoggingProfile()) == ["manage", "loggingProfile", "register"])
        #expect(argv(DeviceCtl().pairDevice(device: "D")) == ["manage", "pair", "--device", "D"])
        #expect(
            argv(DeviceCtl().unpairDevice(device: "D", columns: .init(hideHeaders: true)))
                == ["manage", "unpair", "--device", "D", "--hide-headers"])
        #expect(argv(DeviceCtl().diagnose()) == ["diagnose"])
        #expect(
            argv(
                DeviceCtl().diagnose(
                    finder: false, keepTempDirectory: true, archiveDestination: "/d.zip", archive: false, includeHostSysdiagnose: false))
                == [
                    "diagnose", "--no-finder", "--keep-temp-dir", "--archive-destination", "/d.zip", "--no-archive",
                    "--no-include-host-sysdiagnose",
                ])
    }
}
