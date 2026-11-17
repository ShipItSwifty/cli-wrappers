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

    @Test("The jar comes from the context environment, resolved once at init")
    func jarFromContextEnvironment() {
        let context = ShellContext(environment: ["BUNDLETOOL_JAR": "/opt/bundletool.jar"])
        let command = Bundletool(context: context).validate(bundle: "a.aab").command()
        #expect(command.executableName == "java")
        #expect(command.arguments == ["-jar", "/opt/bundletool.jar", "validate", "--bundle=a.aab"])
    }

    @Test("An explicit jar beats the environment")
    func explicitJarWins() {
        let context = ShellContext(environment: ["BUNDLETOOL_JAR": "/env.jar"])
        let command = Bundletool(context: context, jarPath: "/explicit.jar").getSize(apks: "a.apks").command()
        #expect(command.arguments == ["-jar", "/explicit.jar", "get-size", "total", "--apks=a.apks"])
    }

    @Test("Without a jar the native executable is used")
    func nativeExecutable() {
        let context = ShellContext(environment: [:])
        #expect(Bundletool(context: context).getSize(apks: "a.apks").command().executableName == "bundletool")
        #expect(
            Bundletool(context: context, executablePath: "/opt/bundletool").getDeviceSpec(output: "d.json").command().executableName
                == "/opt/bundletool")
    }

    @Test("The process environment is not consulted")
    func processEnvironmentIgnored() {
        let context = ShellContext(environment: [:])
        #expect(Bundletool(context: context).validate(bundle: "a.aab").command().executableName == "bundletool")
    }
}
