import Testing

@testable import EmulatorKit

@Suite("Emulator")
struct EmulatorTests {
    // MARK: - Emulator

    @Test("Emulator start emits boot options in order")
    func emulatorStartOptions() {
        let args = Emulator(executablePath: "emulator")
            .start(
                avd: "Pixel_7", headless: true, gpu: "swiftshader_indirect", snapshot: .disabled, wipeData: true, readOnly: true, port: 5560
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

    @Test("Snapshot modes and extra arguments")
    func snapshotModes() {
        #expect(
            Emulator(executablePath: "emulator").start(
                avd: "P", snapshot: .loadOnly, port: 5556, additionalArguments: ["-netdelay", "none"]
            )
            .command().arguments == ["-avd", "P", "-no-snapshot-save", "-port", "5556", "-netdelay", "none"])
        #expect(EmulatorSnapshot.saveOnly.arguments == ["-no-snapshot-load"])
    }
}
