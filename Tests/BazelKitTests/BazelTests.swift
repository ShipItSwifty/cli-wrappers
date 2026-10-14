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
}
