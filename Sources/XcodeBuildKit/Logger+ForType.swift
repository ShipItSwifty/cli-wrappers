import Logging

extension Logger {
    /// A logger labelled `"<subsystem>.<TypeName>"`.
    static func forType<T>(subsystem: String = "CLIWrappers", _ type: T.Type) -> Logger {
        Logger(label: "\(subsystem).\(String(describing: T.self))")
    }
}
