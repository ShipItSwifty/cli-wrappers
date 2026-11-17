# ``DeviceCtlKit``

Typed argv builders for every `xcrun devicectl` subcommand.

## Overview

``DeviceCtl`` covers physical-device management: listing devices, installing and launching apps,
copying files, controlling the pasteboard and appearance, simulating location and biometrics, and
managing profiles. Options that group several flags are value types, for example
``DeviceCtlLaunchOptions`` and ``DeviceCtlCopyOptions``.

Operations that change a device are marked **Mutating** in their documentation.

## Topics

### Command family

- ``DeviceCtl``

### Selecting and filtering devices

- ``DeviceCtlFilterOptions``
- ``DeviceCtlColumnOptions``

### Apps

- ``DeviceCtlAppListOptions``
- ``DeviceCtlLaunchOptions``
- ``DeviceCtlOpenURLOptions``

### Files and pasteboard

- ``DeviceCtlFileDomain``
- ``DeviceCtlCopyOptions``
- ``DeviceCtlPasteboardTransfer``
- ``DeviceCtlPasteboardSync``
- ``DeviceCtlPasteboardDataPolicy``

### Display and appearance

- ``DeviceCtlAppearance``
- ``DeviceCtlAppearanceSettings``
- ``DeviceCtlLookAndFeel``
- ``DeviceCtlTextSize``
- ``DeviceCtlColorFilterType``
- ``DeviceCtlOrientation``
- ``DeviceCtlRotationDirection``

### Status bar

- ``DeviceCtlStatusBarOverride``
- ``DeviceCtlStatusBarPreset``
- ``DeviceCtlStatusBarDataNetwork``
- ``DeviceCtlStatusBarConnectionMode``
- ``DeviceCtlStatusBarBatteryState``

### Simulation and device state

- ``DeviceCtlLocationRoute``
- ``DeviceCtlBiometricsAction``
- ``DeviceCtlBiometricOutcome``
- ``DeviceCtlStandbyAction``
- ``DeviceCtlRebootStyle``

### Capture

- ``DeviceCtlCaptureCodec``
- ``DeviceCtlMaskPolicy``

### Profiles

- ``DeviceCtlProfileType``
