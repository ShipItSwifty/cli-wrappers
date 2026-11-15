# ``GradleKit``

Typed argv builders for Gradle Wrapper invocations.

## Overview

``Gradle`` renders global flags first, then the JVM-args property, `-P` properties, and tasks, each task
followed by its own options. Resolution of the executable is explicit and testable: an `executablePath`,
then `./gradlew` under the project directory (checked through an injected `fileExists`), then `gradle`
on `PATH`.

```swift
let output = try await Gradle(context: shell)
    .projectDir("./android")
    .task(.bundleRelease)
    .flag(.noDaemon)
    .run()
```

Gradle tasks write build outputs and can publish or install, so treat running a task as **Mutating**.

## Topics

### Command family

- ``Gradle``

### Tasks, flags, and properties

- ``GradleTask``
- ``GradleFlag``
- ``GradleProperty``
