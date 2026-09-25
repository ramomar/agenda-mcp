extension Optional where Wrapped: Collection {
    /// The wrapped collection, or `nil` if it's empty.
    package var nilIfEmpty: Wrapped? {
        flatMap { $0.isEmpty ? nil : $0 }
    }
}
