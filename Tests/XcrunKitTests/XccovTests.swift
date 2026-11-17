import Testing

@testable import XcrunKit

struct XccovTests {
    private let xccov = Xccov(executablePath: "xcrun")

    @Test(
        "Each operation emits its full argv behind xcrun xccov",
        arguments: [
            (Xccov(executablePath: "xcrun").viewReportJSON(xcresultPath: "a.xcresult"), ["view", "--report", "--json", "a.xcresult"]),
            (
                Xccov(executablePath: "xcrun").viewReport(path: "a.xcresult", scope: .onlyTargets),
                ["view", "--report", "--only-targets", "--json", "a.xcresult"]
            ),
            (
                Xccov(executablePath: "xcrun").viewReport(path: "a.xcresult", scope: .filesForTarget("App"), json: false),
                ["view", "--report", "--files-for-target", "App", "a.xcresult"]
            ),
            (
                Xccov(executablePath: "xcrun").viewReport(path: "a.xcresult", scope: .functionsForFile("A.swift")),
                ["view", "--report", "--functions-for-file", "A.swift", "--json", "a.xcresult"]
            ),
            (
                Xccov(executablePath: "xcrun").viewArchive(xcresultPath: "a.xcresult", file: "/src/A.swift", json: true),
                ["view", "--archive", "--file", "/src/A.swift", "--json", "a.xcresult"]
            ),
            (
                Xccov(executablePath: "xcrun").viewArchive(xcresultPath: "a.xcresult", fileList: true),
                ["view", "--archive", "--file-list", "a.xcresult"]
            ),
            (
                Xccov(executablePath: "xcrun").diff(before: "b.xcresult", after: "a.xcresult", pathEquivalence: "/old,/new"),
                ["diff", "--json", "--path-equivalence", "/old,/new", "b.xcresult", "a.xcresult"]
            ),
            (
                Xccov(executablePath: "xcrun").merge(
                    inputs: ["r1", "a1", "r2", "a2"], outReport: "m.xccovreport", outArchive: "m.xccovarchive"),
                ["merge", "--outReport", "m.xccovreport", "--outArchive", "m.xccovarchive", "r1", "a1", "r2", "a2"]
            ),
        ] as [(Xccov, [String])]
    )
    func operations(xccov: Xccov, expected: [String]) {
        let command = xccov.command()
        #expect(command.executableName == "xcrun")
        #expect(command.arguments == ["xccov"] + expected)
    }

    @Test func keepsTheWholeConfiguration() {
        let command = xccov.viewReportJSON(xcresultPath: "a.xcresult")
            .updatingConfiguration { $0.env("A", "1").workingDirectory("/work") }
            .command()
        #expect(command.environmentOverrides == ["A": "1"])
        #expect(command.workingDirectoryOverride == "/work")
    }
}
