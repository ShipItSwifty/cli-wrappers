import Testing

@testable import CocoaPodsKit

@Suite("Pod")
struct PodTests {
    @Test("Install flags and options")
    func install() {
        let command = Pod().install(repoUpdate: true, deployment: true).projectDirectory("ios").command()
        #expect(command.executableName == "pod")
        #expect(command.arguments == ["install", "--repo-update", "--deployment", "--project-directory=ios"])
    }

    @Test("Bundler runs pod through bundle exec")
    func bundler() {
        let command = Pod(bundler: true).install().command()
        #expect(command.executableName == "bundle")
        #expect(command.arguments == ["exec", "pod", "install"])
    }

    @Test("Update without repo refresh")
    func update() {
        #expect(Pod().update(["Alamofire"], repoUpdate: false).command().arguments == ["update", "Alamofire", "--no-repo-update"])
    }

    @Test(
        "Every operation emits its full argv",
        arguments: [
            (Pod().install(cleanInstall: true), ["install", "--clean-install"]),
            (Pod().update(), ["update"]),
            (Pod().repoUpdate(), ["repo", "update"]),
            (Pod().deintegrate(), ["deintegrate"]),
            (Pod().outdated(), ["outdated"]),
            (Pod().version(), ["--version"]),
            (Pod().outdated().verbose().noANSI(), ["outdated", "--verbose", "--no-ansi"]),
        ] as [(Pod, [String])]
    )
    func operations(pod: Pod, expected: [String]) {
        #expect(pod.command().arguments == expected)
    }

    @Test("An explicit executable replaces both bundle and pod")
    func explicitExecutable() {
        #expect(Pod(executablePath: "/opt/pod").version().command().executableName == "/opt/pod")
    }
}
