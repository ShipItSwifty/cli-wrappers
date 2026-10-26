import Foundation
import WrapperSupport

// `device simulate`: locations, status bar overrides, and biometric events.
extension DeviceCtl {
    // MARK: - Location

    /// `device simulate location coordinate`. The simulation lasts until cleared.
    ///
    /// The coordinates use the `--name=value` form: devicectl reads a separate `-122.03` as an
    /// unknown option, so every western or southern coordinate would be rejected otherwise.
    ///
    /// **Mutating**.
    public func simulateLocation(latitude: Double, longitude: Double, device: String) -> Self {
        deviceOperation(
            ["device", "simulate", "location", "coordinate"], device: device,
            ["--latitude=\(latitude)", "--longitude=\(longitude)"])
    }

    /// `device simulate location clear`.
    ///
    /// **Mutating**.
    public func clearSimulatedLocation(device: String) -> Self {
        deviceOperation(["device", "simulate", "location", "clear"], device: device)
    }

    /// `device simulate location list`: the device's pre-defined scenarios.
    public func listLocationScenarios(device: String) -> Self {
        deviceOperation(["device", "simulate", "location", "list"], device: device)
    }

    /// `device simulate location route`: moves the device along waypoints.
    ///
    /// **Mutating**.
    public func simulateLocationRoute(_ route: DeviceCtlLocationRoute, device: String) -> Self {
        deviceOperation(["device", "simulate", "location", "route"], device: device, route.arguments)
    }

    /// `device simulate location scenario`.
    ///
    /// - Parameter nameOrFile: A scenario from ``listLocationScenarios(device:)``, or the path of a
    ///   scenario file inside the simulator runtime.
    ///
    /// **Mutating**.
    public func simulateLocationScenario(_ nameOrFile: String, device: String) -> Self {
        modified(deviceOperation(["device", "simulate", "location", "scenario"], device: device)) { $0.trailing = [nameOrFile] }
    }

    // MARK: - Status bar

    /// `device simulate statusBar override`. Overrides are cosmetic.
    ///
    /// **Mutating**.
    public func overrideStatusBar(_ override: DeviceCtlStatusBarOverride, device: String) -> Self {
        deviceOperation(["device", "simulate", "statusBar", "override"], device: device, override.arguments)
    }

    /// `device simulate statusBar preset`.
    ///
    /// **Mutating**.
    public func applyStatusBarPreset(_ preset: DeviceCtlStatusBarPreset, device: String) -> Self {
        modified(deviceOperation(["device", "simulate", "statusBar", "preset"], device: device)) { $0.trailing = [preset.rawValue] }
    }

    /// `device simulate statusBar clear`.
    ///
    /// **Mutating**.
    public func clearStatusBar(device: String) -> Self {
        deviceOperation(["device", "simulate", "statusBar", "clear"], device: device)
    }

    /// `device simulate statusBar show`: the overrides currently applied.
    public func showStatusBar(device: String) -> Self {
        deviceOperation(["device", "simulate", "statusBar", "show"], device: device)
    }

    // MARK: - Biometrics

    /// `device simulate biometrics`: presents a match or a failure for every supported biometric
    /// type. Biometrics must be enrolled; see ``biometrics(_:device:)``.
    ///
    /// **Mutating**.
    public func simulateBiometrics(_ outcome: DeviceCtlBiometricOutcome, device: String) -> Self {
        deviceOperation(["device", "simulate", "biometrics"], device: device, ["--\(outcome.rawValue)"])
    }
}
