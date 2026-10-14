import Testing

@testable import AVDManagerKit

@Suite("AVDManager")
struct AVDManagerTests {
    @Test("Resolves cmdline-tools/latest before the legacy tools directory, then PATH")
    func resolution() {
        let manager = AVDManager(context: .init(environment: ["ANDROID_HOME": "/nonexistent-sdk"]))
        #expect(manager.command().executableName == "avdmanager")
        #expect(AVDManager.sdkRelativePaths.first == "cmdline-tools/latest/bin/avdmanager")
    }

    @Test("Create, list, delete emit avdmanager grammar")
    func operations() {
        let manager = AVDManager(executablePath: "avdmanager")
        #expect(manager.listAVDs().command().arguments == ["list", "avd", "-c"])
        #expect(
            manager.createAVD(
                name: "P", systemImage: "system-images;android-35;google_apis;arm64-v8a", deviceProfile: "pixel_8", force: true
            )
            .command().arguments == [
                "create", "avd", "--name", "P", "--package", "system-images;android-35;google_apis;arm64-v8a", "--device", "pixel_8",
                "--force",
            ])
        #expect(manager.deleteAVD(name: "P").command().arguments == ["delete", "avd", "--name", "P"])
        #expect(manager.moveAVD(name: "P", renameTo: "Q").command().arguments == ["move", "avd", "--name", "P", "--rename", "Q"])
    }
}
