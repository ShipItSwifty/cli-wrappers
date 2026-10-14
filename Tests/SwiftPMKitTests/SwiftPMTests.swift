import Testing

@testable import SwiftPMKit

@Suite("SwiftPM")
struct SwiftPMTests {
    @Test("Package tests keep argument boundaries and every output option")
    func packageTests() {
        #expect(
            SwiftPM().test(
                packagePath: "package path", scratchPath: "scratch path", eventStream: "events.jsonl", attachments: "attachments",
                coverage: true, skipBuild: true, filter: "Suite/test", skip: "Integration", xunit: "xctest.xml"
            ).command().arguments == [
                "test", "--package-path", "package path", "--parallel", "--event-stream-output-path", "events.jsonl",
                "--xunit-output", "xctest.xml", "--scratch-path", "scratch path", "--attachments-path", "attachments",
                "--enable-code-coverage", "--skip-build", "--filter", "Suite/test", "--skip", "Integration",
            ])
        #expect(
            SwiftPM().test(packagePath: ".", eventStream: "events.jsonl", workers: 1).command().arguments == [
                "test", "--package-path", ".", "--parallel", "--num-workers", "1", "--event-stream-output-path", "events.jsonl",
            ], "--parallel stays: without it SwiftPM writes no XCTest results")
    }

    @Test("Coverage path, format lint, build, and manifest inspection")
    func otherOperations() {
        #expect(
            SwiftPM().codeCoveragePath(packagePath: "p", scratchPath: "s").command().arguments == [
                "test", "--package-path", "p", "--show-codecov-path", "--scratch-path", "s",
            ])
        #expect(
            SwiftPM().formatLint(paths: ["Sources"], configuration: ".swift-format").command().arguments == [
                "format", "lint", "--recursive", "--strict", "--configuration", ".swift-format", "Sources",
            ])
        #expect(
            SwiftPM().build(packagePath: "p", product: "cli", configuration: .release).command().arguments == [
                "build", "--package-path", "p", "--configuration", "release", "--product", "cli",
            ])
        #expect(
            SwiftPM().describePackage(packagePath: "p").command().arguments == [
                "package", "--package-path", "p", "describe", "--type", "json",
            ])
        #expect(SwiftPM().command().executableName == "swift")
    }
}
