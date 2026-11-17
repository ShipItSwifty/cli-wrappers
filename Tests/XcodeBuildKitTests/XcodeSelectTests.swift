import Testing

@testable import XcodeBuildKit

struct XcodeSelectTests {
    @Test func printsTheDeveloperDirectory() {
        let command = XcodeSelect().printPath().command()
        #expect(command.executableName == "xcode-select")
        #expect(command.arguments == ["-p"])
    }

    @Test(
        "Selects or installs the developer tools",
        arguments: [
            (XcodeSelect(executablePath: "xcode-select").install(), ["--install"]),
            (
                XcodeSelect(executablePath: "xcode-select").switchPath("/Applications/Xcode.app/Contents/Developer"),
                [
                    "--switch", "/Applications/Xcode.app/Contents/Developer",
                ]
            ),
        ] as [(XcodeSelect, [String])]
    )
    func mutatingOperations(xcodeSelect: XcodeSelect, expected: [String]) {
        #expect(xcodeSelect.command().arguments == expected)
    }

    @Test func honoursExecutablePath() {
        #expect(XcodeSelect(executablePath: "/usr/bin/xcode-select").printPath().command().executableName == "/usr/bin/xcode-select")
    }
}
