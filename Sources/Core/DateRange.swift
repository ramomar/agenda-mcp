import Foundation

/// A validated, non-empty span of time.
public struct DateRange: Sendable, Hashable, Encodable {
    /// How far past `start` a range extends when no end is given.
    public static let defaultLength = DateComponents(day: 7)

    public let start: Date
    public let end: Date

    /// Creates a range, defaulting `start` to now and `end` to ``defaultLength`` after `start`.
    public init(
        start: Date? = nil,
        end: Date? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws(AgendaError) {
        let start = start ?? now
        let end = end ?? calendar.date(byAdding: Self.defaultLength, to: start) ?? start
        guard start < end else { throw .invalidDateRange(start: start, end: end) }

        self.start = start
        self.end = end
    }
}
