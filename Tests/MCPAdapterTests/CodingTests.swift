import Foundation
import Testing
import TestSupport
@testable import MCPAdapter

@Suite struct DateParsingTests {
    private struct Box: Decodable { let date: Date }

    private func parse(_ string: String) throws -> Date {
        try JSONDecoder.toolArguments.decode(Box.self, from: Data(#"{"date":"\#(string)"}"#.utf8)).date
    }

    @Test func parsesSupportedFormats() throws {
        #expect(try parse("2026-09-23") == .local(2026, 9, 23))
        #expect(try parse("2026-09-23T14:30:00") == .local(2026, 9, 23, 14, 30))
        #expect(try parse("2026-09-23T12:00:00Z") == Date(timeIntervalSince1970: 1_790_164_800))
        #expect(try parse("2026-09-23T14:00:00+02:00") == Date(timeIntervalSince1970: 1_790_164_800))
        #expect(try parse("2026-09-23T12:00:00.500Z") == Date(timeIntervalSince1970: 1_790_164_800.5))
    }

    @Test func rejectsGarbage() {
        #expect(throws: DecodingError.self) { try parse("next tuesday") }
    }

    @Test func formatsLocalTimestampWithOffset() {
        let formatted = Date.local(2026, 9, 23, 9).formatted(.localTimestamp)
        #expect(formatted.wholeMatch(of: /2026-09-23T09:00:00(Z|[+-]\d{2}:\d{2})/) != nil)
    }
}
