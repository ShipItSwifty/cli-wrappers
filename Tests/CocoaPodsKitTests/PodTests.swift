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
}
