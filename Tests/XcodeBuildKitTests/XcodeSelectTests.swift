import Testing

@testable import XcodeBuildKit

struct XcodeSelectTests {
    @Test func printsTheDeveloperDirectory() {
        let command = XcodeSelect().printPath().command()
        #expect(command.executableName == "xcode-select")
        #expect(command.arguments == ["-p"])
    }

    @Test func honoursExecutablePath() {
        #expect(XcodeSelect(executablePath: "/usr/bin/xcode-select").printPath().command().executableName == "/usr/bin/xcode-select")
    }
}
