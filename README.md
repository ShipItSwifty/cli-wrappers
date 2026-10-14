# cli-wrappers

Typed, testable Swift wrappers for the command-line tools behind mobile builds, tests, and
devices. Every wrapper builds an exact argv (no shell strings) and runs it through
[SwiftyShell](https://github.com/maniramezan/SwiftyShell), so commands can be asserted in unit
tests and executed, captured, or spawned the same way.

Import only the tools you drive. Each one is its own library product:

| Area | Product | Wraps |
| --- | --- | --- |
| Apple | `XcodeBuildKit` | `xcodebuild`, `xcode-select`, destination discovery |
| | `XcrunKit` | `xcrun`, `simctl`, `xcresulttool`, `xccov`, `agvtool` |
| | `DeviceCtlKit` | `xcrun devicectl` (physical devices) |
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

Build mechanisms, device lifecycle, and test execution built on these wrappers live in
[`ShipItSwifty/mobile-kits`](https://github.com/ShipItSwifty/mobile-kits).

## License

MIT
