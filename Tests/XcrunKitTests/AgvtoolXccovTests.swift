import Foundation
import Testing

@testable import XcrunKit

struct AgvtoolXccovTests {
    @Test func buildsAgvtoolCommands() {
        #expect(
            Agvtool().whatMarketingVersionTerse().command().arguments == [
                "agvtool", "what-marketing-version", "-terse",
            ])
        #expect(
            Agvtool().newVersionAll("42").command().arguments == [
                "agvtool", "new-version", "-all", "42",
            ])
    }
    @Test func buildsXccovCommand() {
        let command = Xccov().viewReportJSON(xcresultPath: "build/tests.xcresult").command()

        #expect(command.executableName == "xcrun")
        #expect(command.arguments == ["xccov", "view", "--report", "--json", "build/tests.xcresult"])
    }
}
