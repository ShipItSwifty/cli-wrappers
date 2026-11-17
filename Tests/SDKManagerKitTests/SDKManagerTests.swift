import Testing

@testable import SDKManagerKit

@Suite("SDKManager")
struct SDKManagerTests {
    @Test("Options follow the operation")
    func operations() {
        let manager = SDKManager(executablePath: "sdkmanager")
        #expect(
            manager.install(["platform-tools", "emulator"]).sdkRoot("/sdk").command().arguments == [
                "platform-tools", "emulator", "--sdk_root=/sdk",
            ])
        #expect(manager.list(installedOnly: true).command().arguments == ["--list_installed"])
        #expect(manager.uninstall(["emulator"]).command().arguments == ["--uninstall", "emulator"])
        #expect(manager.licenses().channel(0).command().arguments == ["--licenses", "--channel=0"])
    }

    @Test(
        "Every operation emits its full argv",
        arguments: [
            (SDKManager(executablePath: "sdkmanager").list(), ["--list"]),
            (SDKManager(executablePath: "sdkmanager").updateAll(), ["--update"]),
            (SDKManager(executablePath: "sdkmanager").version(), ["--version"]),
            (SDKManager(executablePath: "sdkmanager").install(["a;b"]).includeObsolete(), ["a;b", "--include_obsolete"]),
            (
                SDKManager(executablePath: "sdkmanager").list().sdkRoot("/sdk").channel(3),
                ["--list", "--sdk_root=/sdk", "--channel=3"]
            ),
        ] as [(SDKManager, [String])]
    )
    func operations(manager: SDKManager, expected: [String]) {
        #expect(manager.command().arguments == expected)
    }

    @Test("Options set before the operation still follow it")
    func optionsFollowOperation() {
        let command = SDKManager(executablePath: "sdkmanager").sdkRoot("/sdk").uninstall(["emulator"]).command()
        #expect(command.arguments == ["--uninstall", "emulator", "--sdk_root=/sdk"])
    }

    @Test("Executable path is honoured")
    func executablePath() {
        #expect(SDKManager(executablePath: "/opt/sdkmanager").version().command().executableName == "/opt/sdkmanager")
    }
}
