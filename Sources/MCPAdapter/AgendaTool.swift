import Foundation
import MCP

/// An MCP tool with typed arguments and output.
///
/// Arguments are decoded from the client's JSON using snake_case keys and flexible ISO 8601 dates;
/// the output is returned to the client as pretty-printed JSON text.
protocol AgendaTool: Sendable {
    associatedtype Arguments: Decodable
    associatedtype Output: Encodable

    var name: String { get }
    var description: String { get }
    var inputSchema: Value { get }

    func run(_ arguments: Arguments) async throws -> Output
}

extension AgendaTool {
    var definition: Tool {
        Tool(
            name: name,
            description: description,
            inputSchema: inputSchema,
            annotations: .init(readOnlyHint: true)
        )
    }

    /// Decodes `arguments`, runs the tool, and wraps the outcome as an MCP tool result.
    ///
    /// Failures are reported to the model as tool errors rather than protocol errors, per the MCP spec.
    func call(with arguments: [String: Value]?) async -> CallTool.Result {
        do {
            let arguments = try JSONDecoder.toolArguments.decode(
                Arguments.self,
                from: JSONEncoder().encode(arguments ?? [:])
            )
            let output = try JSONEncoder.toolOutput.encode(await run(arguments))
            return .text(String(decoding: output, as: UTF8.self))
        } catch let error as DecodingError {
            return .text("Invalid arguments: \(error.summary)", isError: true)
        } catch {
            return .text(error.localizedDescription, isError: true)
        }
    }
}

extension CallTool.Result {
    /// A result with a single text block.
    static func text(_ text: String, isError: Bool? = nil) -> Self {
        CallTool.Result(content: [.text(text: text, annotations: nil, _meta: nil)], isError: isError)
    }
}
