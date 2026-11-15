import Testing

@testable import SecurityKit

struct SecurityCLITests {
    @Test func buildsAvailabilityProbeWithSupportedHelpSubcommand() {
        let command = SecurityCLI()
            .help()
            .command()

        #expect(command.executableName == "security")
        #expect(command.arguments == ["help"])
    }

    @Test func buildsCreateKeychainCommand() {
        let command = SecurityCLI()
            .createKeychain(name: "ci.keychain", password: "secret")
            .command()

        #expect(command.arguments == ["create-keychain", "-p", "secret", "ci.keychain"])
    }

    @Test func buildsCertificateImportWithTrustedApplications() {
        let command = SecurityCLI()
            .importCertificate(
                at: "/tmp/cert.p12",
                keychainName: "ci.keychain",
                password: "p12pass",
                trustedApplications: ["/usr/bin/codesign", "/usr/bin/security"]
            )
            .command()

        #expect(
            command.arguments == [
                "import", "/tmp/cert.p12",
                "-k", "ci.keychain",
                "-P", "p12pass",
                "-T", "/usr/bin/codesign",
                "-T", "/usr/bin/security",
            ])
    }

    @Test(
        "Every operation emits its full argv",
        arguments: [
            (SecurityCLI().help("import"), ["help", "import"]),
            (SecurityCLI().createKeychain(name: "ci.keychain"), ["create-keychain", "ci.keychain"]),
            (
                SecurityCLI().setKeychainSettings(name: "ci.keychain", timeout: 3600),
                ["set-keychain-settings", "-lut", "3600", "ci.keychain"]
            ),
            (SecurityCLI().setUserKeychainSearchList(["a", "b"]), ["list-keychains", "-d", "user", "-s", "a", "b"]),
            (
                SecurityCLI().setKeyPartitionList(services: "apple:", password: "pw", keychainName: "ci.keychain"),
                ["set-key-partition-list", "-S", "apple:", "-s", "-k", "pw", "ci.keychain"]
            ),
            (SecurityCLI().unlockKeychain(name: "ci.keychain", password: "pw"), ["unlock-keychain", "-p", "pw", "ci.keychain"]),
            (SecurityCLI().unlockKeychain(name: "ci.keychain"), ["unlock-keychain", "ci.keychain"]),
            (SecurityCLI().deleteKeychain(name: "ci.keychain"), ["delete-keychain", "ci.keychain"]),
        ] as [(SecurityCLI, [String])]
    )
    func operations(security: SecurityCLI, expected: [String]) {
        #expect(security.command().arguments == expected)
    }

    @Test func promptingFormsNeverCarryAPassword() {
        #expect(!SecurityCLI().unlockKeychain(name: "k").command().arguments.contains("-p"))
        #expect(!SecurityCLI().createKeychain(name: "k").command().arguments.contains("-p"))
    }
}
