import Foundation

public enum AgendaError: LocalizedError, Hashable {
    case invalidDateRange(start: Date, end: Date)
    case unknownLists([String], available: [String])

    public var errorDescription: String? {
        switch self {
        case .invalidDateRange(let start, let end):
            "The end (\(end.formatted())) must be after the start (\(start.formatted()))."
        case .unknownLists(let names, let available):
            "No list matched \(names.formatted()). Available: \(available.formatted())."
        }
    }
}
