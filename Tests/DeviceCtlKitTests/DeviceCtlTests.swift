import Testing

@testable import DeviceCtlKit

@Suite("DeviceCtl")
struct DeviceCtlTests {
    @Test("Runs through xcrun and appends global options after the operation")
    func listDevicesWithJSONOutput() {
        let command = DeviceCtl().listDevices().jsonOutput().deviceTimeout(seconds: 20).command()
        #expect(command.executableName == "xcrun")
        #expect(command.arguments == ["devicectl", "list", "devices", "--json-output", "-", "--timeout", "20"])
    }

    @Test("Launch keeps options before the bundle id and app arguments")
    func launchOrdering() {
        let arguments = DeviceCtl()
            .launch(
                bundleID: "com.example", device: "D1", terminateExisting: true, environment: ["B": "2", "A": "1"], arguments: ["-flag"]
            )
            .jsonOutput("/tmp/out.json")
            .command()
            .arguments
        #expect(
            arguments == [
                "devicectl", "device", "process", "launch", "--device", "D1", "--terminate-existing",
                "--environment-variables", #"{"A":"1","B":"2"}"#, "--json-output", "/tmp/out.json", "com.example", "-flag",
            ])
    }

    @Test("Device operations emit the documented grammar")
    func deviceOperations() {
        #expect(
            DeviceCtl().install(appPath: "A.app", device: "D").command().arguments.dropFirst() == [
                "device", "install", "app", "--device", "D", "A.app",
            ])
        #expect(
            DeviceCtl().uninstall(bundleID: "b", device: "D").command().arguments.dropFirst() == [
                "device", "uninstall", "app", "--device", "D", "b",
            ])
        #expect(
            DeviceCtl().signal("SIGKILL", pid: 42, device: "D").command().arguments.dropFirst()
                == ["device", "process", "signal", "--device", "D", "--pid", "42", "--signal", "SIGKILL"])
        #expect(
            DeviceCtl().simulateLocation(latitude: 1.5, longitude: -2, device: "D").command().arguments.dropFirst()
                == ["device", "simulate", "location", "coordinate", "--device", "D", "--latitude", "1.5", "--longitude", "-2.0"])
        #expect(DeviceCtl().appearance(.dark, device: "D").command().arguments.last == "dark")
        #expect(DeviceCtl().apps(device: "D", bundleID: "b").command().arguments.suffix(2) == ["--bundle-id", "b"])
    }

    @Test("Selecting a new operation drops the previous launch positionals")
    func operationResetsTrailing() {
        let arguments = DeviceCtl().launch(bundleID: "b", device: "D").listDevices().command().arguments
        #expect(arguments == ["devicectl", "list", "devices"])
    }
}
