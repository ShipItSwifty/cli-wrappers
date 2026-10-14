---
name: tool-wrapper
description: Add a new command-line tool wrapper to cli-wrappers, or extend an existing one (XcodeBuildKit, XcrunKit, DeviceCtlKit, GradleKit, AdbKit, EmulatorKit, AVDManagerKit, SDKManagerKit, BundletoolKit, AndroidCLIKit, FlutterKit, ReactNativeKit, SwiftPMKit, BazelKit, TuistCLIKit, CocoaPodsKit, CodesignKit, SecurityKit, PlutilKit, IProxyKit, FrameitKit, XcodeGenKit). Use when a consumer needs a flag, subcommand, or tool the wrappers do not model yet, or when a wrapper's argv looks wrong.
---

# Add or extend a tool wrapper

Each wrapped tool is its own library product (`<Tool>Kit`) that depends only on SwiftyShell and
the internal `WrapperSupport` target. Wrappers build argv; they hold no policy (retries, defaults
chosen for a workflow, error mapping). That belongs to `mobile-kits` or the consuming app.

## New tool

1. Add `("<Tool>Kit", [])` to the `wrappers` list in `Package.swift`; the product, target, and
   test target follow from it.
2. `Sources/<Tool>Kit/<Tool>.swift`, following the `CommandSpec` pattern:

```swift
import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for `tool`. ...
public struct Tool: RunnableCommandFamily {
    private var spec: CommandSpec
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), executablePath: String = "tool") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// `tool sub --flag <value>`.
    public func sub(value: String) -> Self { modified(self) { $0.spec.arguments = ["sub", "--flag", value] } }

    public func command() -> Command { spec.command() }   // pure: builds argv, launches nothing
}
```

## Rules

- **Argument placement matches the tool.** Keep separate state for parts the tool orders
  (Bazel: startup options, command, options, targets, `--` args; devicectl: options before a
  launched app's bundle id and argv; Gradle: global flags before tasks, task options after their
  task). Render them in `command()`, never by appending to a flat array.
- Selecting a new operation replaces the previous one, including its positionals.
- `run()` executes the command, so name a tool's own `run` subcommand differently
  (`runTarget`, `runApp`, `runIOS`).
- Secrets: prefer file/env sources (`BundletoolPassword.file`) over argv, which other users can see.
- Executables: honour an explicit `executablePath`, then SDK environment variables via
  `AndroidSDK.executable(_:fallback:environment:)`, then `PATH`.
- No `#if os(macOS)` around argv construction: Linux builds and tests every wrapper. Gate only a
  test that runs the real tool.
- Mark device- or machine-mutating operations **Mutating** in their DocC.
- Never enable a SwiftyShell trait from this package. Traits unify across the whole build graph,
  and the `Swift` trait adds a type named `Swift` that shadows the standard library module in
  every consumer.

## Tests

In `Tests/<Tool>KitTests/`, assert the **entire** argv (`command().arguments == [...]`), and test
ordering-sensitive cases explicitly. Pure helpers take injected inputs (`environment:`,
`fileExists:`), so tests never touch the machine.
