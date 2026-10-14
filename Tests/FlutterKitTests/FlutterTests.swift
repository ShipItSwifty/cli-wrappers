import Testing

@testable import FlutterKit

@Suite("Flutter")
struct FlutterTests {
    @Test("Release conveniences keep their established argv")
    func releaseBuilds() {
        #expect(
            Flutter().buildIOS(flavor: "prod", dartDefines: ["B": "2", "A": "1"], target: "lib/main_prod.dart").command().arguments == [
                "build", "ios", "--release", "--no-codesign", "--flavor", "prod", "--dart-define=A=1", "--dart-define=B=2", "--target",
                "lib/main_prod.dart",
            ])
        #expect(Flutter().buildIPA().command().arguments == ["build", "ipa", "--release"])
        #expect(Flutter().buildAppBundle(flavor: "f").command().arguments == ["build", "appbundle", "--release", "--flavor", "f"])
        #expect(Flutter().buildAPK().command().arguments == ["build", "apk", "--release"])
    }

    @Test("Simulator debug build and version overrides")
    func simulatorBuild() {
        #expect(
            Flutter().build(.ios, mode: .debug, simulator: true, buildName: "1.2.0", buildNumber: "7").command().arguments == [
                "build", "ios", "--simulator", "--debug", "--build-name=1.2.0", "--build-number=7",
            ])
    }

    @Test("Device and test operations")
    func devicesAndTests() {
        #expect(Flutter().devices().command().arguments == ["devices", "--machine"])
        #expect(
            Flutter().install(device: "emulator-5554", mode: .debug).command().arguments == ["install", "-d", "emulator-5554", "--debug"])
        #expect(
            Flutter().integrationTest(device: "U", name: "login").command().arguments == [
                "test", "integration_test", "-d", "U", "--machine", "--name", "login",
            ])
        #expect(Flutter().testMachine(coverage: true, name: "x").command().arguments == ["test", "--machine", "--name", "x", "--coverage"])
        #expect(Flutter().pubGet(enforceLockfile: true).command().arguments == ["pub", "get", "--enforce-lockfile"])
        #expect(Flutter().version(machine: true).command().arguments == ["--version", "--machine"])
    }

    @Test("FVM-style prefixes run flutter through another executable")
    func prefix() {
        let command = Flutter(executablePath: "fvm", prefix: ["flutter"]).analyze().command()
        #expect(command.executableName == "fvm")
        #expect(command.arguments == ["flutter", "analyze"])
    }
}
