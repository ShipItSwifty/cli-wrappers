import Testing

@testable import BundletoolKit

@Suite("Bundletool signing")
struct BundletoolSigningTests {
    // MARK: - Bundletool

    @Test("Bundletool signing overload uses file password sources, mode, and overwrite")
    func bundletoolSigning() {
        let args = Bundletool(jarPath: "/opt/bundletool.jar")
            .buildApks(
                bundle: "app.aab",
                output: "app.apks",
                signing: .init(keystorePath: "release.jks", keystorePassword: .file("/secrets/ks"), keyAlias: "upload"),
                mode: .universal,
                overwrite: true
            )
            .command()
            .arguments
        #expect(
            args == [
                "-jar", "/opt/bundletool.jar", "build-apks", "--bundle=app.aab", "--output=app.apks", "--ks=release.jks",
                "--ks-pass=file:/secrets/ks", "--ks-key-alias=upload", "--mode=universal", "--overwrite",
            ])
    }

    @Test("Bundletool string passwords keep the pass: prefix and install-apks can target a device")
    func bundletoolLegacyPasswordsAndDeviceID() {
        let build = Bundletool(jarPath: "b.jar")
            .buildApks(bundle: "a.aab", output: "a.apks", keystorePath: "k.jks", keystorePassword: "pw", keyAlias: "k", keyPassword: "kp")
            .command()
            .arguments
        #expect(build.contains("--ks-pass=pass:pw"))
        #expect(build.contains("--key-pass=pass:kp"))

        let install = Bundletool(jarPath: "b.jar").installApks(apks: "a.apks", deviceID: "emulator-5554").command().arguments
        #expect(install.suffix(3) == ["install-apks", "--apks=a.apks", "--device-id=emulator-5554"])
    }
}
