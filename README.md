# cli-wrappers

[![CI](https://github.com/ShipItSwifty/cli-wrappers/actions/workflows/ci.yml/badge.svg)](https://github.com/ShipItSwifty/cli-wrappers/actions/workflows/ci.yml)
[![Documentation](https://github.com/ShipItSwifty/cli-wrappers/actions/workflows/docs.yml/badge.svg)](https://shipitswifty.github.io/cli-wrappers/documentation/)
![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-orange)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-lightgrey)

Typed, testable Swift wrappers for the command-line tools behind mobile builds, tests, and
devices. Every wrapper builds an exact argv (no shell strings) and runs it through
[SwiftyShell](https://github.com/maniramezan/SwiftyShell), so commands can be asserted in unit
tests and executed, captured, or spawned the same way.

Import only the tools you drive. Each one is its own library product:

| Area | Product | Wraps |
| --- | --- | --- |
| Apple | `XcodeBuildKit` | `xcodebuild`, `xcode-select`, destination discovery |
| | `XcrunKit` | `xcrun`, `simctl`, `xcresulttool`, `xccov`, `agvtool` |
| | `LLVMCovKit` | `xcrun llvm-cov` |
| | `DeviceCtlKit` | `xcrun devicectl` (physical devices and, from Xcode 27, simulators): every `device`, `list`, `manage`, and `diagnose` command |
| | `IProxyKit` | `iproxy` (USB port forwarding to iOS devices) |
| | `XcodeGenKit` / `TuistCLIKit` | `xcodegen`, `tuist` |
| | `CocoaPodsKit` | `pod` (optionally `bundle exec pod`) |
| | `CodesignKit` / `SecurityKit` | `codesign`, `security` (keychains) |
| | `PlutilKit` / `FrameitKit` | `plutil`, `frameit` |
| Android | `GradleKit` | Gradle tasks, flags, properties |
| | `AdbKit` | `adb` |
| | `EmulatorKit` / `AVDManagerKit` / `SDKManagerKit` | `emulator`, `avdmanager`, `sdkmanager` |
| | `BundletoolKit` | `bundletool` |
| | `AndroidCLIKit` | Google's `android` CLI |
| Cross-platform | `FlutterKit` | `flutter` |
| | `ReactNativeKit` | `react-native`, `expo` (via npx, yarn, pnpm, or bunx) |
| | `SwiftPMKit` | `swift` package build, test, coverage, format, and manifest inspection |
| | `BazelKit` | `bazel` / `bazelisk` |

## Install

Pre-1.0, track `main`:

```swift
.package(url: "https://github.com/ShipItSwifty/cli-wrappers.git", branch: "main"),
```

```swift
.target(name: "MyTool", dependencies: [
    .product(name: "XcrunKit", package: "cli-wrappers"),
    .product(name: "AdbKit", package: "cli-wrappers"),
])
```

Swift 6.2+, macOS 15+ or Linux. Wrappers build on Linux; running an Apple tool there fails because
the executable does not exist.

## Usage

```swift
import BazelKit
import SwiftyShell
import XcrunKit

let shell = ShellContext()

try await Simctl(context: shell).boot("A1B2-…").run()

let summary = try await XCResultTool(context: shell)
    .testResultsSummary(path: "build/tests.xcresult")
    .run()

let command = Bazel(context: shell)
    .test(["//app:unit_tests"])
    .option(.config("ci"))
    .option(.buildEventJSONFile("bep.json"))
    .command()
// command.arguments == ["test", "--config=ci", "--build_event_json_file=bep.json", "//app:unit_tests"]
```

### The shared command surface

Every wrapper conforms to SwiftyShell's `RunnableCommandFamily`, so they all work the same way:

| Member | What it does |
| --- | --- |
| `command()` | Builds the `Command` (executable plus argv). Pure: launches nothing and touches no files. |
| `run()` / `spawn()` | Executes the command and returns captured output, or starts it as a long-lived process. |
| `settingStdoutDestination(_:)` / `settingStderrDestination(_:)` | Captures, discards, tees, or redirects a stream to a file. |
| `updatingConfiguration(_:)` | Applies a timeout, environment variables, working directory, or output limit. |
| `init(context:executablePath:)` | Selects the executable. Android tools also look under `ANDROID_HOME` / `ANDROID_SDK_ROOT` in the context's environment before falling back to `PATH`. |

Selecting an operation replaces the previous one, and a wrapper adds no retries, defaults, or error
mapping: those belong to the caller.

An Android example, running one instrumentation test with extras:

```swift
import AdbKit

let launch = Adb(context: shell)
    .serial("emulator-5554")
    .amStartActivity(
        component: "com.example/.MainActivity",
        wait: true,
        typedExtras: [.string("mode", "test"), .bool("debug", true)]
    )
    .updatingConfiguration { $0.timeout(30) }

try await launch.run()
```

### Asserting argv in your tests

`command()` is a pure value, so a consumer can check exactly what would run without a device or the
tool installed, on any platform:

```swift
import Testing
import XcrunKit

@Test func launchesWithEnvironment() {
    let command = Simctl(executablePath: "xcrun")
        .launch("booted", bundleIdentifier: "com.example.app", environment: ["MODE": "test"])
        .command()

    #expect(command.arguments == ["simctl", "launch", "booted", "com.example.app"])
    #expect(command.environmentOverrides == ["SIMCTL_CHILD_MODE": "test"])
}
```

Pass `executablePath:` in tests so the assertion does not depend on which SDK is installed on the
machine running them.

Build mechanisms, device lifecycle, and test execution built on these wrappers live in
[`ShipItSwifty/mobile-kits`](https://github.com/ShipItSwifty/mobile-kits).

## Documentation

API documentation: <https://shipitswifty.github.io/cli-wrappers/documentation/>

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
