import Testing

@testable import EmulatorKit

@Suite("Emulator")
struct EmulatorTests {
    // MARK: - Emulator

    @Test("Emulator start emits boot options in order")
    func emulatorStartOptions() {
        let args = Emulator(executablePath: "emulator")
            .start(
                avd: "Pixel_7", headless: true, gpu: "swiftshader_indirect", noSnapshot: true, wipeData: true, readOnly: true, port: 5560
            )
            .command()
            .arguments
        #expect(
            args == [
                "-avd", "Pixel_7", "-no-window", "-no-audio", "-no-boot-anim", "-gpu", "swiftshader_indirect",
                "-no-snapshot", "-wipe-data", "-read-only", "-port", "5560",
            ])
    }

    @Test("Emulator resolves the SDK binary from ANDROID_HOME, then ANDROID_SDK_ROOT, then PATH")
    func emulatorExecutableResolution() {
        let existing: Set<String> = ["/sdk-root/emulator/emulator"]
        let exists: (String) -> Bool = { existing.contains($0) }

        #expect(
            Emulator.resolveExecutable(environment: ["ANDROID_SDK_ROOT": "/sdk-root"], fileExists: exists) == "/sdk-root/emulator/emulator")
        #expect(
            Emulator.resolveExecutable(environment: ["ANDROID_HOME": "/missing", "ANDROID_SDK_ROOT": "/sdk-root"], fileExists: exists)
                == "/sdk-root/emulator/emulator")
        #expect(Emulator.resolveExecutable(environment: [:], fileExists: exists) == "emulator")
        #expect(Emulator(executablePath: "/custom/emulator").list().command().executableName == "/custom/emulator")
    }
}
