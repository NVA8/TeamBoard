import Foundation

enum RepositoryError: Error {
    case featureUnavailable
    case notAuthenticated
    case notFound
    case decodingFailed
    case encodingFailed
}

