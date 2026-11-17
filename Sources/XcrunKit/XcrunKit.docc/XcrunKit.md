# ``XcrunKit``

Typed argv builders for `xcrun` and the tools it launches: `simctl`, `xcresulttool`, `xccov`, and `agvtool`.

## Overview

Every family here runs through `xcrun`, so each initializer takes an `executablePath` for the `xcrun`
binary. ``Simctl`` models simulator management, including app launch with arguments and environment.
``XCResultTool`` reads `.xcresult` bundles and ``Xccov`` reads their coverage.

```swift
let launch = Simctl(context: shell)
    .launch(
        "booted", bundleIdentifier: "com.example.app",
        arguments: ["-ui-test"], environment: ["MODE": "test"], terminateRunning: true
    )
```

## Topics

### Simulators

- ``Simctl``
- ``SimctlCommand``
- ``SimctlListTarget``
- ``SimctlLaunchConsole``

### Result bundles and coverage

- ``XCResultTool``
- ``XCResultLogType``
- ``XCResultExportKind``
- ``Xccov``
- ``XccovScope``

### Versioning

- ``Agvtool``

### The `xcrun` front end

- ``Xcrun``
- ``XcrunOption``
