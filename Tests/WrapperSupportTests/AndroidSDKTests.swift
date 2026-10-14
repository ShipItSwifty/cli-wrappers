import Testing

@testable import WrapperSupport

@Suite("AndroidSDK")
struct AndroidSDKTests {
    @Test("Prefers ANDROID_HOME, then ANDROID_SDK_ROOT, then the first existing relative path")
    func resolution() {
        let existing: Set<String> = ["/root/tools/bin/avdmanager", "/home/cmdline-tools/latest/bin/avdmanager"]
        let paths = ["cmdline-tools/latest/bin/avdmanager", "tools/bin/avdmanager"]
        #expect(
            AndroidSDK.executable(paths, fallback: "avdmanager", environment: ["ANDROID_SDK_ROOT": "/root"], fileExists: existing.contains)
                == "/root/tools/bin/avdmanager")
        #expect(
            AndroidSDK.executable(
                paths, fallback: "avdmanager", environment: ["ANDROID_HOME": "/home", "ANDROID_SDK_ROOT": "/root"],
                fileExists: existing.contains
            ) == "/home/cmdline-tools/latest/bin/avdmanager")
        #expect(
            AndroidSDK.executable(paths, fallback: "avdmanager", environment: ["ANDROID_HOME": ""], fileExists: existing.contains)
                == "avdmanager")
    }
}
