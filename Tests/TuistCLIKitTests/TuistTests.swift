import Testing

@testable import TuistCLIKit

@Suite("Tuist")
struct TuistTests {
    @Test("Generate puts options before focus targets")
    func generate() {
        #expect(
            Tuist().generate(binaryCache: false, focusTargets: ["App"]).path("Proj").command().arguments == [
                "generate", "--no-open", "--no-binary-cache", "--path", "Proj", "App",
            ])
    }

    @Test("Build and test take a scheme positional")
    func buildAndTest() {
        #expect(Tuist().build(scheme: "App").configuration("Debug").command().arguments == ["build", "--configuration", "Debug", "App"])
        #expect(Tuist().test(scheme: "App", testPlan: "CI").command().arguments == ["test", "--test-plan", "CI", "App"])
        #expect(Tuist().install().command().arguments == ["install"])
    }
}
