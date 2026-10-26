import Foundation
import WrapperSupport

// MARK: - Table output

/// The `--columns`, `--hide-default-columns`, and `--hide-headers` options of commands that print a table.
public struct DeviceCtlColumnOptions: Sendable, Equatable, Hashable {
    /// Extra data columns; `"*"` selects every column. A value is a column title or a JSON field path.
    public var columns: [String]
    public var hideDefaultColumns: Bool
    public var hideHeaders: Bool

    public init(columns: [String] = [], hideDefaultColumns: Bool = false, hideHeaders: Bool = false) {
        self.columns = columns
        self.hideDefaultColumns = hideDefaultColumns
        self.hideHeaders = hideHeaders
    }

    var arguments: [String] {
        repeated("--columns", columns) + flag("--hide-default-columns", hideDefaultColumns) + flag("--hide-headers", hideHeaders)
    }
}

/// The filtering and column options shared by commands that list rows (`list devices`,
/// `device info apps`, `device info processes`, `device info files`, `device pairings list`,
/// `device profile list`).
public struct DeviceCtlFilterOptions: Sendable, Equatable, Hashable {
    /// A case-insensitive substring matched across every column (`--search`).
    public var search: String?
    /// An NSPredicate over column titles or JSON field paths (`--filter`).
    public var filter: String?
    /// A column title to sort by (`--sort-by`).
    public var sortBy: String?
    public var columns: DeviceCtlColumnOptions

    public init(
        search: String? = nil,
        filter: String? = nil,
        sortBy: String? = nil,
        columns: DeviceCtlColumnOptions = .init()
    ) {
        self.search = search
        self.filter = filter
        self.sortBy = sortBy
        self.columns = columns
    }

    var arguments: [String] {
        optionalOption("--search", search) + optionalOption("--filter", filter) + optionalOption("--sort-by", sortBy) + columns.arguments
    }
}

// MARK: - Files

/// A file service domain: where `device copy` and `device info files` read and write on the device.
public struct DeviceCtlFileDomain: Sendable, Equatable, Hashable {
    /// The `--domain-type` values devicectl accepts.
    public enum Kind: String, Sendable, CaseIterable {
        case temporary
        case appDataContainer
        case appGroupDataContainer
        case systemCrashLogs
    }

    public var kind: Kind
    /// Context for the domain: the bundle id of an app data container, an app group identifier, or a
    /// client-chosen string that names a private temporary directory.
    public var identifier: String?

    public init(_ kind: Kind, identifier: String? = nil) {
        self.kind = kind
        self.identifier = identifier
    }

    /// A private scratch directory named by `identifier`.
    public static func temporary(_ identifier: String) -> Self { .init(.temporary, identifier: identifier) }
    /// An app's data container.
    public static func appData(bundleID: String) -> Self { .init(.appDataContainer, identifier: bundleID) }
    /// An app group's container.
    public static func appGroup(_ identifier: String) -> Self { .init(.appGroupDataContainer, identifier: identifier) }
    /// The system crash logs.
    public static var crashLogs: Self { .init(.systemCrashLogs) }

    var arguments: [String] {
        ["--domain-type", kind.rawValue] + optionalOption("--domain-identifier", identifier)
    }
}

/// The options `device copy to` and `device copy from` share beyond their source and domain.
public struct DeviceCtlCopyOptions: Sendable, Equatable, Hashable {
    /// The user to target; only relevant for some domains (`--user`).
    public var user: String?
    /// Remove files from the destination directory that are not in the source. Directories only
    /// (`--remove-existing-content`).
    public var removeExistingContent: Bool?

    public init(user: String? = nil, removeExistingContent: Bool? = nil) {
        self.user = user
        self.removeExistingContent = removeExistingContent
    }

    var arguments: [String] {
        optionalOption("--user", user) + (removeExistingContent.map { ["--remove-existing-content", $0 ? "true" : "false"] } ?? [])
    }
}

// MARK: - Apps

/// The filters of `device info apps`. `nil` leaves devicectl's default.
public struct DeviceCtlAppListOptions: Sendable, Equatable, Hashable {
    public var includeAppClips: Bool?
    public var includeRemovableApps: Bool?
    public var includeDefaultApps: Bool?
    /// Only apps whose data container is accessible.
    public var requireContainerAccess: Bool
    public var includeAppGroupIdentifiers: Bool
    public var includeContainerPaths: Bool
    /// Every app; devicectl ignores the other filters when set.
    public var includeAllApps: Bool

    public init(
        includeAppClips: Bool? = nil,
        includeRemovableApps: Bool? = nil,
        includeDefaultApps: Bool? = nil,
        requireContainerAccess: Bool = false,
        includeAppGroupIdentifiers: Bool = false,
        includeContainerPaths: Bool = false,
        includeAllApps: Bool = false
    ) {
        self.includeAppClips = includeAppClips
        self.includeRemovableApps = includeRemovableApps
        self.includeDefaultApps = includeDefaultApps
        self.requireContainerAccess = requireContainerAccess
        self.includeAppGroupIdentifiers = includeAppGroupIdentifiers
        self.includeContainerPaths = includeContainerPaths
        self.includeAllApps = includeAllApps
    }

    var arguments: [String] {
        toggle("include-app-clips", includeAppClips) + toggle("include-removable-apps", includeRemovableApps)
            + toggle("include-default-apps", includeDefaultApps) + flag("--require-container-access", requireContainerAccess)
            + flag("--include-app-group-identifiers", includeAppGroupIdentifiers) + flag("--include-container-paths", includeContainerPaths)
            + flag("--include-all-apps", includeAllApps)
    }
}

/// The launch options beyond those `DeviceCtl.launch` takes directly.
public struct DeviceCtlLaunchOptions: Sendable, Equatable, Hashable {
    /// The user id or name to run as (`--user`).
    public var user: String?
    public var workingDirectory: String?
    /// The architecture slice to prefer (`--arch`).
    public var architecture: String?
    /// Whether to bring the app to the foreground; `nil` leaves devicectl's default (activate).
    public var activate: Bool?
    /// A display's unique id from `device info displays` (`--display`).
    public var display: String?
    /// The `launchServicesIdentifier` returned by `device install app`, base64-encoded.
    public var launchPersistentIdentifier: String?

    public init(
        user: String? = nil,
        workingDirectory: String? = nil,
        architecture: String? = nil,
        activate: Bool? = nil,
        display: String? = nil,
        launchPersistentIdentifier: String? = nil
    ) {
        self.user = user
        self.workingDirectory = workingDirectory
        self.architecture = architecture
        self.activate = activate
        self.display = display
        self.launchPersistentIdentifier = launchPersistentIdentifier
    }

    var arguments: [String] {
        optionalOption("--user", user) + optionalOption("--working-directory", workingDirectory) + optionalOption("--arch", architecture)
            + toggle("activate", activate) + optionalOption("--display", display)
            + optionalOption("--launch-persistent-identifier", launchPersistentIdentifier)
    }
}

/// The options of `device process openURL`.
public struct DeviceCtlOpenURLOptions: Sendable, Equatable, Hashable {
    public var activate: Bool?
    public var terminateExisting: Bool
    public var display: String?

    public init(activate: Bool? = nil, terminateExisting: Bool = false, display: String? = nil) {
        self.activate = activate
        self.terminateExisting = terminateExisting
        self.display = display
    }

    var arguments: [String] {
        toggle("activate", activate) + flag("--terminate-existing", terminateExisting) + optionalOption("--display", display)
    }
}

// MARK: - Capture

/// A video codec for `device capture screen-record`.
public enum DeviceCtlCaptureCodec: String, Sendable, CaseIterable {
    case h264
    case hevc
}

/// How `device capture screen-record` treats a device's bezel mask.
public enum DeviceCtlMaskPolicy: String, Sendable, CaseIterable {
    case ignored
    case premultipliedAlpha
    case black
}

// MARK: - Settings

/// The user interface style of `device settings appearance --mode`.
public enum DeviceCtlAppearance: String, Sendable, CaseIterable {
    case light
    case dark
}

/// The Liquid Glass look of `device settings appearance --look-and-feel`.
public enum DeviceCtlLookAndFeel: String, Sendable, CaseIterable {
    case clear
    case tinted
}

/// A text size for `device settings appearance --text-size`. The `accessibility…` sizes need
/// ``DeviceCtlAppearanceSettings/largerAccessibilitySizes``.
public enum DeviceCtlTextSize: String, Sendable, CaseIterable {
    case extraSmall = "extra-small"
    case small
    case medium
    case large
    case extraLarge = "extra-large"
    case extraExtraLarge = "extra-extra-large"
    case extraExtraExtraLarge = "extra-extra-extra-large"
    case accessibilityMedium = "accessibility-medium"
    case accessibilityLarge = "accessibility-large"
    case accessibilityExtraLarge = "accessibility-extra-large"
    case accessibilityExtraExtraLarge = "accessibility-extra-extra-large"
    case accessibilityExtraExtraExtraLarge = "accessibility-extra-extra-extra-large"
}

/// A colour filter for `device settings appearance --color-filter-type`.
public enum DeviceCtlColorFilterType: String, Sendable, CaseIterable {
    case grayscale
    case protanopia
    case deuteranopia
    case tritanopia
}

/// Everything `device settings appearance` can change. Each `nil` field is left alone.
public struct DeviceCtlAppearanceSettings: Sendable, Equatable, Hashable {
    public var mode: DeviceCtlAppearance?
    public var lookAndFeel: DeviceCtlLookAndFeel?
    public var textSize: DeviceCtlTextSize?
    public var largerAccessibilitySizes: Bool?
    public var increaseContrast: Bool?
    public var reduceMotion: Bool?
    public var reduceTransparency: Bool?
    public var showBorders: Bool?
    /// From 0.0 (fully translucent) to 1.0 (fully opaque).
    public var liquidGlassOpacity: Double?
    public var colorFilter: Bool?
    public var colorFilterType: DeviceCtlColorFilterType?
    /// From 0.25 to 1.0; does not apply to grayscale.
    public var colorFilterIntensity: Double?

    public init(
        mode: DeviceCtlAppearance? = nil,
        lookAndFeel: DeviceCtlLookAndFeel? = nil,
        textSize: DeviceCtlTextSize? = nil,
        largerAccessibilitySizes: Bool? = nil,
        increaseContrast: Bool? = nil,
        reduceMotion: Bool? = nil,
        reduceTransparency: Bool? = nil,
        showBorders: Bool? = nil,
        liquidGlassOpacity: Double? = nil,
        colorFilter: Bool? = nil,
        colorFilterType: DeviceCtlColorFilterType? = nil,
        colorFilterIntensity: Double? = nil
    ) {
        self.mode = mode
        self.lookAndFeel = lookAndFeel
        self.textSize = textSize
        self.largerAccessibilitySizes = largerAccessibilitySizes
        self.increaseContrast = increaseContrast
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
        self.showBorders = showBorders
        self.liquidGlassOpacity = liquidGlassOpacity
        self.colorFilter = colorFilter
        self.colorFilterType = colorFilterType
        self.colorFilterIntensity = colorFilterIntensity
    }

    var arguments: [String] {
        optionalOption("--mode", mode?.rawValue) + optionalOption("--look-and-feel", lookAndFeel?.rawValue)
            + optionalOption("--text-size", textSize?.rawValue) + onOff("--larger-accessibility-sizes", largerAccessibilitySizes)
            + onOff("--increase-contrast", increaseContrast) + onOff("--reduce-motion", reduceMotion)
            + onOff("--reduce-transparency", reduceTransparency) + onOff("--show-borders", showBorders)
            + optionalNumber("--liquid-glass-opacity", liquidGlassOpacity) + onOff("--color-filter", colorFilter)
            + optionalOption("--color-filter-type", colorFilterType?.rawValue)
            + optionalNumber("--color-filter-intensity", colorFilterIntensity)
    }
}

/// What `device settings biometrics` does. Query reports enrolment without changing it.
public enum DeviceCtlBiometricsAction: Sendable, Equatable, Hashable, CaseIterable {
    case query
    case enable
    case disable

    var arguments: [String] {
        switch self {
        case .query: []
        case .enable: ["--enable"]
        case .disable: ["--disable"]
        }
    }
}

/// The result `device simulate biometrics` presents.
public enum DeviceCtlBiometricOutcome: String, Sendable, CaseIterable {
    case success
    case failure
}

/// What `device settings standby` does to StandBy.
public enum DeviceCtlStandbyAction: String, Sendable, CaseIterable {
    case show
    case hide
}

/// A device orientation for `device orientation set`.
public enum DeviceCtlOrientation: String, Sendable, CaseIterable {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    case faceUp
    case faceDown
}

/// A relative rotation for `device orientation rotate`.
public enum DeviceCtlRotationDirection: String, Sendable, CaseIterable {
    case left
    case right
}

/// The reboot style of `device reboot --style`.
public enum DeviceCtlRebootStyle: String, Sendable, CaseIterable {
    case full
    case userspace
}

// MARK: - Simulation

/// A location route for `device simulate location route`.
public enum DeviceCtlLocationRoute: Sendable, Equatable, Hashable {
    /// How often the simulated location updates.
    public enum Pacing: Sendable, Equatable, Hashable {
        /// After travelling this many meters.
        case distance(meters: Double)
        /// After this many seconds.
        case interval(seconds: Double)
    }

    /// A latitude/longitude pair.
    public struct Waypoint: Sendable, Equatable, Hashable {
        public var latitude: Double
        public var longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        var argument: String { "\(latitude),\(longitude)" }
    }

    /// A JSON route file (`--route-file`); devicectl ignores every other route option.
    case file(String)
    /// Waypoints, pacing, and a speed in meters per second.
    case waypoints([Waypoint], pacing: Pacing, speed: Double?)

    var arguments: [String] {
        switch self {
        case .file(let path):
            return ["--route-file", path]
        case .waypoints(let waypoints, let pacing, let speed):
            var values: [String]
            switch pacing {
            case .distance(let meters): values = ["--mode", "distance", "--distance", String(meters)]
            case .interval(let seconds): values = ["--mode", "interval", "--interval", String(seconds)]
            }
            values += optionalNumber("--speed", speed)
            values += ["--waypoints"] + waypoints.map(\.argument)
            return values
        }
    }
}

/// A data network for `device simulate statusBar override --data-network`.
public enum DeviceCtlStatusBarDataNetwork: String, Sendable, CaseIterable {
    case hide
    case wifi
    case hotspot
    case oneX = "1x"
    case gprs = "GPRS"
    case edge = "Edge"
    case umts = "UMTS"
    case fourG = "4G"
    case lte = "LTE"
    case lteA = "LTEA"
    case ltePlus = "LTEPlus"
    case fiveG = "5G"
    case fiveGPlus = "5GPlus"
    case fiveGUWB = "5GUWB"
    case fiveGUC = "5GUC"
}

/// A Wi-Fi or cellular connection mode in a status bar override.
public enum DeviceCtlStatusBarConnectionMode: String, Sendable, CaseIterable {
    case notSupported
    case searching
    case failed
    case active
}

/// A battery state in a status bar override.
public enum DeviceCtlStatusBarBatteryState: String, Sendable, CaseIterable {
    case draining
    case charging
    case charged
}

/// The indicators `device simulate statusBar override` can set. Overrides are cosmetic.
public struct DeviceCtlStatusBarOverride: Sendable, Equatable, Hashable {
    /// The time string to show, e.g. `9:41`.
    public var time: String?
    public var dataNetwork: DeviceCtlStatusBarDataNetwork?
    public var wifiMode: DeviceCtlStatusBarConnectionMode?
    /// Bars, 1 to 3; only valid with ``DeviceCtlStatusBarConnectionMode/active``.
    public var wifiStrength: Int?
    public var cellularMode: DeviceCtlStatusBarConnectionMode?
    /// Bars, 1 to 5; only valid with ``DeviceCtlStatusBarConnectionMode/active``.
    public var cellularStrength: Int?
    public var batteryState: DeviceCtlStatusBarBatteryState?
    /// Percentage, 0 to 100.
    public var batteryLevel: Int?
    /// Shows the "Not Charging" indicator.
    public var batteryFailingToCharge: Bool

    public init(
        time: String? = nil,
        dataNetwork: DeviceCtlStatusBarDataNetwork? = nil,
        wifiMode: DeviceCtlStatusBarConnectionMode? = nil,
        wifiStrength: Int? = nil,
        cellularMode: DeviceCtlStatusBarConnectionMode? = nil,
        cellularStrength: Int? = nil,
        batteryState: DeviceCtlStatusBarBatteryState? = nil,
        batteryLevel: Int? = nil,
        batteryFailingToCharge: Bool = false
    ) {
        self.time = time
        self.dataNetwork = dataNetwork
        self.wifiMode = wifiMode
        self.wifiStrength = wifiStrength
        self.cellularMode = cellularMode
        self.cellularStrength = cellularStrength
        self.batteryState = batteryState
        self.batteryLevel = batteryLevel
        self.batteryFailingToCharge = batteryFailingToCharge
    }

    var arguments: [String] {
        optionalOption("--time", time) + optionalOption("--data-network", dataNetwork?.rawValue)
            + optionalOption("--wifi-mode", wifiMode?.rawValue) + optionalNumber("--wifi-strength", wifiStrength)
            + optionalOption("--cellular-mode", cellularMode?.rawValue) + optionalNumber("--cellular-strength", cellularStrength)
            + optionalOption("--battery-state", batteryState?.rawValue) + optionalNumber("--battery-level", batteryLevel)
            + flag("--battery-failing-to-charge", batteryFailingToCharge)
    }
}

/// A preset for `device simulate statusBar preset`.
public enum DeviceCtlStatusBarPreset: String, Sendable, CaseIterable {
    /// 9:41, full battery, strong signals: the classic Apple screenshot setup.
    case screenshot
    /// 5% battery draining with weak signals.
    case lowBattery = "low-battery"
    /// No cellular or Wi-Fi connectivity.
    case noService = "no-service"
    /// 50% battery charging with moderate signals.
    case charging
}

// MARK: - Pasteboard

/// How pasteboard data crosses between host and device.
public enum DeviceCtlPasteboardDataPolicy: String, Sendable, CaseIterable {
    /// Preserve the source's promise/data state.
    case matchSource = "match-source"
    /// Fetch all data eagerly.
    case allResolved = "all-resolved"
    /// Promise every type and fulfil on demand.
    case allPromised = "all-promised"
    /// Resolve the primary type eagerly and promise the rest.
    case promiseSecondary = "promise-secondary"
    /// Resolve types under the byte threshold eagerly and promise the rest. devicectl's default.
    case thresholdData = "threshold-data"
}

/// The options of `device pasteboard transfer to` and `transfer from`.
public struct DeviceCtlPasteboardTransfer: Sendable, Equatable, Hashable {
    public var dataPolicy: DeviceCtlPasteboardDataPolicy?
    /// The size under which `threshold-data` resolves a type eagerly.
    public var dataThresholdBytes: Int?
    /// The device pasteboard's name; devicectl defaults to `general`.
    public var devicePasteboard: String?
    /// The host pasteboard's name; devicectl defaults to `general`.
    public var hostPasteboard: String?

    public init(
        dataPolicy: DeviceCtlPasteboardDataPolicy? = nil,
        dataThresholdBytes: Int? = nil,
        devicePasteboard: String? = nil,
        hostPasteboard: String? = nil
    ) {
        self.dataPolicy = dataPolicy
        self.dataThresholdBytes = dataThresholdBytes
        self.devicePasteboard = devicePasteboard
        self.hostPasteboard = hostPasteboard
    }

    var arguments: [String] {
        optionalOption("--data-policy", dataPolicy?.rawValue) + optionalNumber("--data-threshold-bytes", dataThresholdBytes)
            + optionalOption("--device-pasteboard", devicePasteboard) + optionalOption("--host-pasteboard", hostPasteboard)
    }
}

/// The options of `device pasteboard sync-with-host`.
public struct DeviceCtlPasteboardSync: Sendable, Equatable, Hashable {
    /// Seconds to keep syncing; devicectl defaults to 300 and requires it to be under the global timeout.
    public var sessionTimeout: Int?
    public var devicePasteboard: String?
    public var hostPasteboard: String?
    /// The policy for both directions, overridden by the two directional policies.
    public var dataPolicy: DeviceCtlPasteboardDataPolicy?
    public var dataPolicyFromDevice: DeviceCtlPasteboardDataPolicy?
    public var dataPolicyToDevice: DeviceCtlPasteboardDataPolicy?
    public var dataThresholdBytes: Int?

    public init(
        sessionTimeout: Int? = nil,
        devicePasteboard: String? = nil,
        hostPasteboard: String? = nil,
        dataPolicy: DeviceCtlPasteboardDataPolicy? = nil,
        dataPolicyFromDevice: DeviceCtlPasteboardDataPolicy? = nil,
        dataPolicyToDevice: DeviceCtlPasteboardDataPolicy? = nil,
        dataThresholdBytes: Int? = nil
    ) {
        self.sessionTimeout = sessionTimeout
        self.devicePasteboard = devicePasteboard
        self.hostPasteboard = hostPasteboard
        self.dataPolicy = dataPolicy
        self.dataPolicyFromDevice = dataPolicyFromDevice
        self.dataPolicyToDevice = dataPolicyToDevice
        self.dataThresholdBytes = dataThresholdBytes
    }

    var arguments: [String] {
        optionalNumber("--session-timeout", sessionTimeout) + optionalOption("--device-pasteboard", devicePasteboard)
            + optionalOption("--host-pasteboard", hostPasteboard) + optionalOption("--data-policy", dataPolicy?.rawValue)
            + optionalOption("--data-policy-from-device", dataPolicyFromDevice?.rawValue)
            + optionalOption("--data-policy-to-device", dataPolicyToDevice?.rawValue)
            + optionalNumber("--data-threshold-bytes", dataThresholdBytes)
    }
}

// MARK: - Profiles

/// A profile type for the `device profile` commands.
public enum DeviceCtlProfileType: String, Sendable, CaseIterable {
    /// A `.mobileprovision` provisioning profile.
    case provisioning
    /// A `.mobileconfig` configuration profile.
    case configuration
}
