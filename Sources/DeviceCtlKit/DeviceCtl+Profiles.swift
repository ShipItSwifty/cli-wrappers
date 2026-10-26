import Foundation
import WrapperSupport

// `device profile` and `device pairings`.
extension DeviceCtl {
    // MARK: - Profiles

    /// `device profile install`: installs provisioning (`.mobileprovision`) or configuration
    /// (`.mobileconfig`) profiles in one batch. Each is validated first.
    ///
    /// - Parameters:
    ///   - type: Forces the type; devicectl detects it from the file extension otherwise.
    ///   - replaceExisting: Replace a profile with the same identifier; devicectl does by default.
    ///
    /// **Mutating**.
    public func installProfiles(
        _ paths: [String],
        device: String,
        type: DeviceCtlProfileType? = nil,
        replaceExisting: Bool? = nil
    ) -> Self {
        modified(
            deviceOperation(
                ["device", "profile", "install"], device: device,
                optionalOption("--type", type?.rawValue) + toggle("replace-existing", replaceExisting))
        ) { $0.trailing = paths }
    }

    /// `device profile list`.
    public func listProfiles(device: String, type: DeviceCtlProfileType? = nil, filter: DeviceCtlFilterOptions = .init()) -> Self {
        deviceOperation(["device", "profile", "list"], device: device, optionalOption("--type", type?.rawValue) + filter.arguments)
    }

    /// `device profile remove`.
    ///
    /// - Parameters:
    ///   - identifiers: Provisioning profile UUIDs or configuration profile payload identifiers.
    ///   - type: devicectl infers it from the identifier format when `nil`.
    ///   - forceRemoval: Succeed even when the profile is not on the device.
    ///
    /// **Mutating**.
    public func removeProfiles(
        _ identifiers: [String],
        device: String,
        type: DeviceCtlProfileType? = nil,
        forceRemoval: Bool = false
    ) -> Self {
        modified(
            deviceOperation(
                ["device", "profile", "remove"], device: device,
                optionalOption("--type", type?.rawValue) + flag("--force-removal", forceRemoval))
        ) { $0.trailing = identifiers }
    }

    /// `device profile validate`: checks profiles without installing them. Local; needs no device.
    public func validateProfiles(_ paths: [String], type: DeviceCtlProfileType? = nil) -> Self {
        modified(operation(["device", "profile", "validate"] + optionalOption("--type", type?.rawValue))) { $0.trailing = paths }
    }

    // MARK: - Pairings

    /// `device pairings list`: the devices paired with `device`.
    public func listPairings(device: String, filter: DeviceCtlFilterOptions = .init()) -> Self {
        deviceOperation(["device", "pairings", "list"], device: device, filter.arguments)
    }

    /// `device pairings pair`: pairs a phone with one or more watches.
    ///
    /// **Mutating**.
    public func pairWatches(phone: String, watches: [String]) -> Self {
        operation(["device", "pairings", "pair", "--phone", phone] + repeated("--watch", watches))
    }

    /// `device pairings set-active`: makes an existing phone and watch pairing the active one.
    ///
    /// **Mutating**.
    public func setActivePairing(phone: String, watch: String) -> Self {
        operation(["device", "pairings", "set-active", "--phone", phone, "--watch", watch])
    }

    /// `device pairings unpair`: unpairs a phone from one or more watches.
    ///
    /// **Mutating**.
    public func unpairWatches(phone: String, watches: [String]) -> Self {
        operation(["device", "pairings", "unpair", "--phone", phone] + repeated("--watch", watches))
    }
}
