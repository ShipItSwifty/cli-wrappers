import Testing

@testable import BazelKit

@Suite("Bazel")
struct BazelTests {
    @Test("Startup options precede the command; options precede targets")
    func ordering() {
        let arguments = Bazel()
            .startupOption(.outputBase("/tmp/ob"))
            .test(["//app:tests", "//lib:tests"])
            .option(.config("ci"))
            .option(.testOutput(.errors))
            .option(.buildEventJSONFile("bep.json"))
            .option(.testFilter("FooTests/testBar"))
            .command()
            .arguments
        #expect(
            arguments == [
                "--output_base=/tmp/ob", "test", "--config=ci", "--test_output=errors", "--build_event_json_file=bep.json",
                "--test_filter=FooTests/testBar", "//app:tests", "//lib:tests",
            ])
    }

    @Test("Run passes program arguments after --")
    func runTarget() {
        #expect(
            Bazel().runTarget("//tools:gen", arguments: ["--out", "x"]).command().arguments == ["run", "//tools:gen", "--", "--out", "x"])
    }

    @Test("Query, info, clean, and environment options")
    func queries() {
        #expect(Bazel().query("deps(//app)", output: .labelKind).command().arguments == ["query", "--output=label_kind", "deps(//app)"])
        #expect(Bazel().info("bazel-bin").command().arguments == ["info", "bazel-bin"])
        #expect(Bazel().clean(expunge: true).command().arguments == ["clean", "--expunge"])
        #expect(BazelOption.testEnv("CI", nil).arguments == ["--test_env=CI"])
        #expect(BazelOption.actionEnv("A", "1").arguments == ["--action_env=A=1"])
        #expect(Bazel(executablePath: "bazelisk").version().command().executableName == "bazelisk")
    }

    @Test("Several startup options keep their order and precede the command")
    func startupOrdering() {
        let arguments = Bazel()
            .startupOption(.outputBase("/ob"))
            .startupOption(.outputBase("/ob2"))
            .build(["//a"])
            .option(.config("ci"))
            .command()
            .arguments
        #expect(arguments == ["--output_base=/ob", "--output_base=/ob2", "build", "--config=ci", "//a"])
    }

    @Test("Options added before the operation still follow the command")
    func optionsBeforeOperation() {
        #expect(
            Bazel().option(.config("ci")).build(["//a"]).command().arguments == ["build", "--config=ci", "//a"])
    }

    @Test("Selecting another operation drops run arguments and targets")
    func replacesOperation() {
        #expect(Bazel().runTarget("//t", arguments: ["x"]).build(["//a"]).command().arguments == ["build", "//a"])
    }

    @Test(
        "Remaining operations emit their full argv",
        arguments: [
            (Bazel().coverage(["//a"]), ["coverage", "//a"]),
            (Bazel().cquery("deps(//a)"), ["cquery", "deps(//a)"]),
            (Bazel().aquery("//a"), ["aquery", "//a"]),
            (Bazel().mod("graph"), ["mod", "graph"]),
            (Bazel().fetch(["//..."]), ["fetch", "//..."]),
            (Bazel().shutdown(), ["shutdown"]),
            (Bazel().version(), ["version"]),
            (Bazel().info(), ["info"]),
            (Bazel().clean(), ["clean"]),
        ] as [(Bazel, [String])]
    )
    func operations(bazel: Bazel, expected: [String]) {
        #expect(bazel.command().arguments == expected)
    }
}
