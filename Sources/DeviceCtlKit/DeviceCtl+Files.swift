import Foundation
import WrapperSupport

// `device copy` and `device capture`: moving files and screen contents between host and device.
extension DeviceCtl {
    // MARK: - Copy

    /// `device copy to`: copies files or directories to the device, skipping unmodified files.
    ///
    /// - Parameters:
    ///   - sources: Host paths to transfer.
    ///   - domain: The device file domain and its identifier.
    ///   - destination: The device location, relative to the domain.
    ///
    /// **Mutating**.
    public func copyToDevice(
        sources: [String],
        device: String,
        domain: DeviceCtlFileDomain,
        destination: String? = nil,
        options: DeviceCtlCopyOptions = .init()
    ) -> Self {
        deviceOperation(
            ["device", "copy", "to"], device: device,
            repeated("--source", sources) + domain.arguments + optionalOption("--destination", destination) + options.arguments)
    }

    /// `device copy from`: copies a file or directory from the device.
    ///
    /// - Parameters:
    ///   - source: The device path, relative to the domain.
    ///   - destination: The host location to copy to.
    public func copyFromDevice(
        source: String,
        device: String,
        domain: DeviceCtlFileDomain,
        destination: String? = nil,
        options: DeviceCtlCopyOptions = .init()
    ) -> Self {
        deviceOperation(
            ["device", "copy", "from"], device: device,
            ["--source", source] + domain.arguments + optionalOption("--destination", destination) + options.arguments)
    }

    // MARK: - Capture

    /// `device capture screenshot`: saves a PNG.
    ///
    /// - Parameters:
    ///   - destination: A `.png` path on the host.
    ///   - displayUniqueID: A display from ``displays(device:stream:)``; defaults to the primary display.
    public func screenshot(device: String, destination: String, displayUniqueID: String? = nil) -> Self {
        deviceOperation(
            ["device", "capture", "screenshot"], device: device,
            ["--destination", destination] + optionalOption("--display-unique-id", displayUniqueID))
    }

    /// `device capture screen-record`: saves an MP4. Without `duration` it records until the process
    /// is interrupted, so spawn it and tear it down gracefully.
    ///
    /// - Parameters:
    ///   - destination: A `.mp4` path on the host.
    ///   - displayUniqueID: A display from ``displays(device:stream:)``; defaults to the primary display.
    ///   - codec: devicectl defaults to H.264.
    ///   - maskPolicy: How to treat the device bezel; devicectl defaults to ignoring it.
    ///   - duration: Seconds to record before stopping on its own.
    public func screenRecord(
        device: String,
        destination: String,
        displayUniqueID: String? = nil,
        codec: DeviceCtlCaptureCodec? = nil,
        maskPolicy: DeviceCtlMaskPolicy? = nil,
        duration: Double? = nil
    ) -> Self {
        deviceOperation(
            ["device", "capture", "screen-record"], device: device,
            ["--destination", destination] + optionalOption("--display-unique-id", displayUniqueID)
                + optionalOption("--codec", codec?.rawValue) + optionalOption("--mask-policy", maskPolicy?.rawValue)
                + optionalNumber("--duration", duration))
    }
}
