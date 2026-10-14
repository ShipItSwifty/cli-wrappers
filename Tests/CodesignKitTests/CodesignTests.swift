import Testing

@testable import CodesignKit

@Suite("Codesign")
struct CodesignTests {
    @Test("Sign emits hardened runtime, timestamp, and entitlements before the path")
    func sign() {
        #expect(
            Codesign().sign("A.app", identity: "Apple Distribution", entitlements: "e.plist", hardenedRuntime: true, timestamp: true)
                .command().arguments == [
                    "--force", "--sign", "Apple Distribution", "--entitlements", "e.plist", "--options", "runtime", "--timestamp", "A.app",
                ])
        #expect(
            Codesign().sign("A.app", identity: "-", timestamp: false).command().arguments == [
                "--force", "--sign", "-", "--timestamp=none", "A.app",
            ])
    }

    @Test("Verify and inspect")
    func verify() {
        #expect(
            Codesign().verify("A.app", deep: true, strict: true).command().arguments == [
                "--verify", "--verbose=2", "--deep", "--strict", "A.app",
            ])
        #expect(Codesign().entitlements("A.app").command().arguments == ["--display", "--entitlements", "-", "--xml", "A.app"])
    }
}
