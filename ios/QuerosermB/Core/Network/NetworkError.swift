import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(Error)
    case noConnection
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return Strings.Network.invalidURL
        case .invalidResponse:
            return Strings.Network.invalidResponse
        case .serverError(let code):
            return Strings.Network.serverError(code: code)
        case .decodingError:
            return Strings.Network.decoding
        case .noConnection:
            return Strings.Network.noConnection
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
