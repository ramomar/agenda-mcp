import Foundation

extension FormatStyle where Self == Date.ISO8601FormatStyle {
    /// A full timestamp in the user's time zone, such as `2026-09-23T14:00:00+02:00`.
    static var localTimestamp: Self {
        Date.ISO8601FormatStyle(timeZoneSeparator: .colon, timeZone: .current)
    }

    /// A date and time without an offset, interpreted in the user's time zone, such as `2026-09-23T14:00:00`.
    static var localDateTime: Self {
        Date.ISO8601FormatStyle(timeZone: .current)
            .year().month().day()
            .dateTimeSeparator(.standard)
            .time(includingFractionalSeconds: false)
    }

    /// A calendar date in the user's time zone, such as `2026-09-23`.
    static var localDate: Self {
        Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
    }
}

extension JSONDecoder.DateDecodingStrategy {
    /// Accepts ISO 8601 timestamps with an offset, local date-times, and plain dates.
    static var flexibleISO8601: Self {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let formats: [Date.ISO8601FormatStyle] = [
                Date.ISO8601FormatStyle(),
                Date.ISO8601FormatStyle(includingFractionalSeconds: true),
                .localDateTime,
                .localDate,
            ]

            guard let date = formats.lazy.compactMap({ try? Date(string, strategy: $0) }).first else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected an ISO 8601 date such as 2026-09-23 or 2026-09-23T14:00:00, got '\(string)'."
                )
            }
            return date
        }
    }
}

extension JSONDecoder {
    /// Decodes tool arguments: snake_case keys and flexible ISO 8601 dates.
    static var toolArguments: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .flexibleISO8601
        return decoder
    }
}

extension JSONEncoder {
    /// Encodes tool output as readable JSON with local-time timestamps.
    static var toolOutput: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(.localTimestamp))
        }
        return encoder
    }
}

extension DecodingError {
    /// A concise description including the coding path, suitable for reporting back to a model.
    var summary: String {
        switch self {
        case .typeMismatch(_, let context), .valueNotFound(_, let context),
             .keyNotFound(_, let context), .dataCorrupted(let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return path.isEmpty ? context.debugDescription : "\(path): \(context.debugDescription)"
        @unknown default:
            return localizedDescription
        }
    }
}
