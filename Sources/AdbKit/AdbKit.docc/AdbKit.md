# ``AdbKit``

Typed argv builders for the Android Debug Bridge.

## Overview

``Adb`` resolves its executable from `ANDROID_HOME` or `ANDROID_SDK_ROOT` (`platform-tools/adb`) and falls
back to `adb` on `PATH`; pass `executablePath` to override. Target a device with ``Adb/serial(_:)``, which
renders a leading `-s <serial>`.

```swift
let launch = Adb(context: shell)
    .serial("emulator-5554")
    .amStartActivity(
        component: "com.example/.MainActivity", wait: true,
        typedExtras: [.string("mode", "test"), .bool("debug", true)]
    )
```

Operations that change a device are marked **Mutating** in their documentation.

## Topics

### Command family

- ``Adb``

### Intents

- ``AdbIntentExtra``
