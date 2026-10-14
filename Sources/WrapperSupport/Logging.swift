import Logging

extension Logger {
    /// A logger labelled `"<subsystem>.<TypeName>"`. `package` so it never collides with a
    /// consumer's own `forType` helper.
    package static func forType<T>(subsystem: String = "CLIWrappers", _ type: T.Type) -> Logger {
        Logger(label: "\(subsystem).\(String(describing: T.self))")
    }
}
