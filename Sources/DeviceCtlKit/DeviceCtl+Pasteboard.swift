import Foundation
import WrapperSupport

// `device pasteboard` and `device notification`.
extension DeviceCtl {
    // MARK: - Pasteboard

    /// `device pasteboard copy`: puts data on the device pasteboard. Without `files`, devicectl reads
    /// UTF-8 text from stdin and writes it under the plain-text types.
    ///
    /// - Parameters:
    ///   - type: One UTI for non-text data; each file becomes its own pasteboard item.
    ///   - files: Host files to read instead of stdin.
    ///   - pasteboard: The device pasteboard's name; devicectl defaults to `general`.
    ///
    /// **Mutating**.
    public func pasteboardCopy(device: String, type: String? = nil, files: [String] = [], pasteboard: String? = nil) -> Self {
        deviceOperation(
            ["device", "pasteboard", "copy"], device: device,
            optionalOption("--type", type) + repeated("--file", files) + optionalOption("--device-pasteboard", pasteboard))
    }

    /// `device pasteboard paste`: writes the pasteboard contents to stdout, so ``jsonOutput(_:)`` must
    /// be a file path rather than `-`.
    ///
    /// - Parameters:
    ///   - type: The UTI to extract; without it devicectl looks for text.
    ///   - item: The zero-based pasteboard item.
    public func pasteboardPaste(device: String, type: String? = nil, item: Int? = nil, pasteboard: String? = nil) -> Self {
        deviceOperation(
            ["device", "pasteboard", "paste"], device: device,
            optionalOption("--type", type) + optionalNumber("--item", item) + optionalOption("--device-pasteboard", pasteboard))
    }

    /// `device pasteboard info`: every item and flavor with its type and size, transferring no data.
    public func pasteboardInfo(device: String, pasteboard: String? = nil) -> Self {
        deviceOperation(["device", "pasteboard", "info"], device: device, optionalOption("--device-pasteboard", pasteboard))
    }

    /// `device pasteboard monitor`: reports pasteboard changes for `sessionTimeout` seconds (300 by default).
    public func pasteboardMonitor(device: String, sessionTimeout: Int? = nil, pasteboard: String? = nil) -> Self {
        deviceOperation(
            ["device", "pasteboard", "monitor"], device: device,
            optionalNumber("--session-timeout", sessionTimeout) + optionalOption("--device-pasteboard", pasteboard))
    }

    /// `device pasteboard transfer to`: copies the host pasteboard to the device.
    ///
    /// **Mutating**.
    public func pasteboardTransferToDevice(device: String, options: DeviceCtlPasteboardTransfer = .init()) -> Self {
        deviceOperation(["device", "pasteboard", "transfer", "to"], device: device, options.arguments)
    }

    /// `device pasteboard transfer from`: copies the device pasteboard to the host. With a policy that
    /// produces promises, the process stays alive to fulfil them until the host pasteboard changes.
    ///
    /// **Mutating** (the host pasteboard).
    public func pasteboardTransferFromDevice(device: String, options: DeviceCtlPasteboardTransfer = .init()) -> Self {
        deviceOperation(["device", "pasteboard", "transfer", "from"], device: device, options.arguments)
    }

    /// `device pasteboard sync-with-host`: keeps both pasteboards in sync for `sessionTimeout` seconds.
    ///
    /// **Mutating**.
    public func pasteboardSyncWithHost(device: String, options: DeviceCtlPasteboardSync = .init()) -> Self {
        deviceOperation(["device", "pasteboard", "sync-with-host"], device: device, options.arguments)
    }

    // MARK: - Darwin notifications

    /// `device notification post`: posts Darwin notifications.
    ///
    /// **Mutating**.
    public func postNotifications(_ names: [String], device: String) -> Self {
        deviceOperation(["device", "notification", "post"], device: device, repeated("--name", names))
    }

    /// `device notification observe`: waits for Darwin notifications, for `sessionTimeout` seconds
    /// (300 by default). The session timeout must be under the global ``deviceTimeout(seconds:)``.
    public func observeNotifications(_ names: [String], device: String, sessionTimeout: Int? = nil) -> Self {
        deviceOperation(
            ["device", "notification", "observe"], device: device,
            repeated("--name", names) + optionalNumber("--session-timeout", sessionTimeout))
    }
}
