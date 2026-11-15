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

    @Test(
        "Every operation emits its full argv",
        arguments: [
            (Tuist().install(update: true), ["install", "--update"]),
            (Tuist().generate(open: true, binaryCache: true), ["generate", "--binary-cache"]),
            (Tuist().generate(), ["generate", "--no-open"]),
            (Tuist().build(clean: true), ["build", "--clean"]),
            (Tuist().clean(["plugins", "dependencies"]), ["clean", "plugins", "dependencies"]),
            (Tuist().graph(), ["graph", "--format", "json", "--no-open"]),
            (Tuist().graph(format: "dot", outputPath: "out"), ["graph", "--format", "dot", "--no-open", "--output-path", "out"]),
            (Tuist().version(), ["version"]),
        ] as [(Tuist, [String])]
    )
    func operations(tuist: Tuist, expected: [String]) {
        #expect(tuist.command().arguments == expected)
    }

    @Test("Selecting a new operation drops the previous positionals")
    func replacesPositionals() {
        #expect(Tuist().build(scheme: "App").version().command().arguments == ["version"])
    }
}
