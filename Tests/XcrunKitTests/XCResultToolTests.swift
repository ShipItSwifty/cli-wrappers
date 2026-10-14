import Testing

@testable import XcrunKit

struct XCResultToolTests {
    @Test func buildsTestResultQueries() {
        #expect(
            XCResultTool().testResultsSummary(path: "r.xcresult").command().arguments == [
                "xcresulttool", "get", "test-results", "summary", "--path", "r.xcresult", "--compact",
            ])
        #expect(
            XCResultTool().testDetails(testID: "T/a()", path: "r", compact: false).command().arguments == [
                "xcresulttool", "get", "test-results", "test-details", "--test-id", "T/a()", "--path", "r",
            ])
    }

    @Test func buildsExportAndLogCommands() {
        #expect(
            XCResultTool().export(.attachments, path: "r", outputPath: "out").command().arguments == [
                "xcresulttool", "export", "attachments", "--path", "r", "--output-path", "out",
            ])
        #expect(
            XCResultTool().log(path: "r", type: .console).command().arguments == [
                "xcresulttool", "get", "log", "--path", "r", "--type", "console", "--compact",
            ])
        #expect(
            XCResultTool().merge(["a", "b"], outputPath: "m").command().arguments == [
                "xcresulttool", "merge", "--output-path", "m", "a", "b",
            ])
        #expect(XCResultTool().legacyObject(path: "r", id: "X").command().arguments.suffix(2) == ["--id", "X"])
    }

    @Test func buildsSimctlGetenvAndListApps() {
        #expect(
            Simctl().getenv("booted", variable: "RWI_LISTEN_SOCKET").command().arguments == [
                "simctl", "getenv", "booted", "RWI_LISTEN_SOCKET",
            ])
        #expect(Simctl().listApps("U").command().arguments == ["simctl", "listapps", "U"])
    }
}
