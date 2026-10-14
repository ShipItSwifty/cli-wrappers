import SwiftyShell
import Testing

@testable import SwiftPMKit

@Suite("Swift package workflows")
struct SwiftPackageWorkflowTests {
    @Test("Package tests carry the event stream, xunit, and worker options")
    func packageTests() {
        let arguments = Swift()
            .packageTests(
                packagePath: ".", scratchPath: ".build-ci", eventStream: "e.jsonl", coverage: true, filter: "Foo", xunit: "x.xml",
                workers: 1
            )
            .command()
            .arguments
        #expect(
            arguments == [
                "test", "--package-path", ".", "--scratch-path", ".build-ci", "--enable-code-coverage", "--filter", "Foo", "--parallel",
                "--num-workers", "1", "--event-stream-output-path", "e.jsonl", "--xunit-output", "x.xml",
            ])
    }

    @Test("Coverage path, format lint, and manifest inspection")
    func inspection() {
        #expect(Swift().codeCoveragePath(packagePath: "p").command().arguments == ["test", "--package-path", "p", "--show-codecov-path"])
        #expect(
            Swift().formatLint(paths: ["Sources"], configuration: ".swift-format").command().arguments == [
                "format", "lint", "--recursive", "--strict", "--configuration", ".swift-format", "Sources",
            ])
        #expect(
            Swift().describePackage(packagePath: "p").command().arguments == [
                "package", "describe", "--package-path", "p", "--type", "json",
            ])
        #expect(
            Swift().buildProduct("cli", packagePath: "p", configuration: .release).command().arguments == [
                "build", "--package-path", "p", "--configuration", "release", "--product", "cli",
            ])
    }
}
