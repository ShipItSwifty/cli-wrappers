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
}
