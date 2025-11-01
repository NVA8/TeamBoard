import Foundation

/// Type-safe identifier used across the domain layer.
public struct Identifier<T>: Hashable, Codable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String = UUID().uuidString) {
        self.rawValue = rawValue
    }
}

extension Identifier: CustomStringConvertible {
    public var description: String { rawValue }
}

