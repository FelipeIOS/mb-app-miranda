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
            return "URL inválida."
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .serverError(let code):
            return "Erro no servidor (código \(code))."
        case .decodingError:
            return "Erro ao processar os dados. Tente novamente."
        case .noConnection:
            return "Sem conexão com a internet."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
