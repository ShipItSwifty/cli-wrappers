import Foundation
import SwiftyShell
import Synchronization
import Testing

@testable import BundletoolKit

// MARK: - Bundletool command builder tests

@Suite("Bundletool")
struct BundletoolTests {
    @Test("Bundletool validate(bundle:) produces correct arguments")
    func validateBundle() {
        let command = Bundletool()
            .validate(bundle: "./app-release.aab")
            .command()

        let args = command.arguments
        #expect(command.executableName == "bundletool")
        #expect(args.contains("validate"))
        #expect(args.contains("--bundle=./app-release.aab"))
    }

    @Test("Bundletool buildApks produces correct arguments")
    func buildApks() {
        let command = Bundletool()
            .buildApks(bundle: "app-release.aab", output: "app.apks")
            .command()

        let args = command.arguments
        #expect(args.contains("build-apks"))
        #expect(args.contains("--bundle=app-release.aab"))
        #expect(args.contains("--output=app.apks"))
    }
}
