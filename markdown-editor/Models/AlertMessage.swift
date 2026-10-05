import Foundation

/// The title and detail text of an error alert.
struct AlertMessage {
    let title: String
    let message: String

    private static let fallbackTitle = "Something went wrong"

    /// Builds an alert from an error, using its localized description and failure reason when it has them.
    init(error: Error) {
        let localizedError = error as? LocalizedError
        title = localizedError?.errorDescription ?? Self.fallbackTitle
        message = localizedError?.failureReason ?? error.localizedDescription
    }
}
