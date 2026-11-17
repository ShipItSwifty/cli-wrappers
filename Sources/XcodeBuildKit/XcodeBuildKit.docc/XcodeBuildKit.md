# ``XcodeBuildKit``

Typed argv builders for `xcodebuild` and `xcode-select`, plus destination discovery.

## Overview

``XcodeBuild`` builds the argument list for one `xcodebuild` action. Pick the container with
``XcodeBuild/project(_:)`` or ``XcodeBuild/workspace(_:)``, add typed ``XcodeBuildOption`` values and
build settings, then select an action such as ``XcodeBuild/build(clean:)`` or ``XcodeBuild/test()``.
`command()` returns the pure command value; `run()` executes it.

```swift
let output = try await XcodeBuild(context: shell)
    .workspace("App.xcworkspace")
    .option(.scheme("App"))
    .option(.destination("platform=iOS Simulator,id=\(udid)"))
    .option(.parallelTestingEnabled(true))
    .test()
    .run()
```

``DestinationDiscovery`` runs `xcodebuild -showdestinations` and parses the result into
``XcodebuildDestination`` values. It throws when `xcodebuild` fails without listing any destination;
use ``DestinationDiscovery/parseDestinations(from:)`` to apply a different failure policy.

## Topics

### Building and testing

- ``XcodeBuild``
- ``XcodeBuildOption``
- ``XcodeBuildContainer``

### Packaging

- ``XcodeBuildXCFrameworkInput``

### Destinations

- ``DestinationDiscovery``
- ``XcodebuildDestination``

### Developer directory

- ``XcodeSelect``
