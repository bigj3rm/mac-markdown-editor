import Foundation

/// A failed file operation, worded so it can be shown to the user as an alert.
nonisolated enum FileServiceError: LocalizedError {
    case cannotListFolder(URL, underlying: Error)
    case cannotRead(URL, underlying: Error)
    case cannotWrite(URL, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .cannotListFolder(let url, _):
            "Could not open the folder “\(url.lastPathComponent)”."
        case .cannotRead(let url, _):
            "Could not open “\(url.lastPathComponent)”."
        case .cannotWrite(let url, _):
            "Could not save “\(url.lastPathComponent)”."
        }
    }

    /// The system's explanation of what went wrong.
    var failureReason: String? {
        switch self {
        case .cannotListFolder(_, let underlying),
             .cannotRead(_, let underlying),
             .cannotWrite(_, let underlying):
            underlying.localizedDescription
        }
    }
}
