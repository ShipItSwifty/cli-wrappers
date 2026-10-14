import Testing

@testable import ReactNativeKit

@Suite("React Native and Expo")
struct ReactNativeTests {
    @Test("Build conveniences keep their established argv under npx")
    func builds() {
        let ios = ReactNative().buildIOS(scheme: "App").command()
        #expect(ios.executableName == "npx")
        #expect(ios.arguments == ["react-native", "build-ios", "--mode", "Release", "--scheme", "App"])
        #expect(
            ReactNative().buildAndroid(task: "bundleRelease").command().arguments == [
                "react-native", "build-android", "--mode=release", "--tasks", "bundleRelease",
            ])
    }

    @Test("Runner selects the package manager")
    func runners() {
        let pnpm = ReactNative(runner: .pnpm).config().command()
        #expect(pnpm.executableName == "pnpm")
        #expect(pnpm.arguments == ["exec", "react-native", "config"])
        #expect(ReactNative(runner: .yarn).doctor().command().arguments == ["react-native", "doctor"])
        #expect(ReactNative(runner: .bun).start().command().executableName == "bunx")
    }

    @Test("Run and Metro")
    func runAndStart() {
        #expect(
            ReactNative().runIOS(udid: "U", startPackager: false).command().arguments == [
                "react-native", "run-ios", "--mode", "Debug", "--udid", "U", "--no-packager",
            ])
        #expect(
            ReactNative().runAndroid(deviceID: "emulator-5554", applicationID: "com.x").command().arguments == [
                "react-native", "run-android", "--mode", "debug", "--device", "emulator-5554", "--appId", "com.x",
            ])
        #expect(
            ReactNative().start(port: 8082, resetCache: true).command().arguments == [
                "react-native", "start", "--port", "8082", "--reset-cache",
            ])
    }

    @Test("Bundle writes an offline JS bundle")
    func bundle() {
        #expect(
            ReactNative().bundle(platform: "ios", bundleOutput: "main.jsbundle", assetsDestination: "assets").command().arguments == [
                "react-native", "bundle", "--platform", "ios", "--entry-file", "index.js", "--bundle-output", "main.jsbundle", "--dev",
                "false", "--assets-dest", "assets",
            ])
    }

    @Test("Expo prebuild and run")
    func expo() {
        #expect(
            Expo().prebuild(platform: "ios", clean: true).command().arguments == [
                "expo", "prebuild", "--platform", "ios", "--non-interactive", "--clean",
            ])
        #expect(
            Expo().runAndroid(device: "emulator-5554").command().arguments == [
                "expo", "run:android", "--variant", "debug", "--device", "emulator-5554",
            ])
    }
}
