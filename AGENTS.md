# cli-wrappers — agent guidance

Typed Swift wrappers over the command-line tools mobile automation drives: Xcode and its `xcrun`
tools, physical-device tools, the Android SDK, Gradle, Flutter, React Native/Expo, SwiftPM, Bazel,
Tuist, CocoaPods, and signing tools. Built on [SwiftyShell](https://github.com/maniramezan/SwiftyShell).

Consumers: [`ShipItSwifty/mobile-kits`](https://github.com/ShipItSwifty/mobile-kits) (build, devices,
test execution), [`ShipItSwifty/shipitswifty`](https://github.com/ShipItSwifty/shipitswifty), and Amoo.

## Layout

- One library product per tool: `Sources/<Tool>Kit/`, tests in `Tests/<Tool>KitTests/`.
  Products are generated from the `wrappers` list in `Package.swift`.
- `Sources/WrapperSupport/` (internal, not a product): `CommandSpec`, argv helpers, Android SDK
  binary lookup.
- Wrappers build argv and nothing else: no retries, workflow defaults, or error mapping.

## Commands

```bash
swift build
swift test
swift format lint --recursive --strict --configuration .swift-format Sources Tests Package.swift
swift format --in-place --recursive --configuration .swift-format Sources Tests Package.swift
```

Run the format lint after the final edit. Linux CI builds and tests everything (Swift 6.2 and
latest); no `#if os(macOS)` around argv construction.

## Conventions

- Swift tools 6.2, Swift 6 language mode, `Sendable` public types, Swift Testing.
- Bare SemVer tags (`0.1.0`), no `v` prefix. Pre-1.0, breaking changes are allowed and expected;
  consumers track `main` until the API is stable.
- No `CHANGELOG.md`; release notes go in GitHub Releases.
- Adding or changing a wrapper: follow [`agent-skills/tool-wrapper`](agent-skills/tool-wrapper/SKILL.md).
