import Foundation

enum APIEndpoint {
    static let baseURL = "https://pro-api.coinmarketcap.com"

    case exchangeMap(start: Int, limit: Int)
    case exchangeInfo(ids: String)
    case exchangeAssets(id: Int)

    var path: String {
        switch self {
        case .exchangeMap:   return "/v1/exchange/map"
        case .exchangeInfo:  return "/v1/exchange/info"
        case .exchangeAssets: return "/v1/exchange/assets"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .exchangeMap(start, limit):
            // Sem `sort`: no plano Basic, `sort=volume_24h` costuma limitar o conjunto
            // (ex.: só ~40 itens), e a 2ª página vem vazia. Ordenamos por volume no app
            // após o `/exchange/info` (campo `spot_volume_usd`).
            return [
                URLQueryItem(name: "start", value: "\(start)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        case let .exchangeInfo(ids):
            return [URLQueryItem(name: "id", value: ids)]
        case let .exchangeAssets(id):
            return [URLQueryItem(name: "id", value: "\(id)")]
        }
    }

    func buildURLRequest(apiKey: String) throws -> URLRequest {
        var components = URLComponents(string: APIEndpoint.baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
