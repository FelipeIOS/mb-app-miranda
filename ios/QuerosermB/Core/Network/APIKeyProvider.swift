import Foundation

struct APIKeyProvider {
    static var key: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "CMC_API_KEY") as? String,
              !key.isEmpty else {
            assertionFailure("⚠️ CMC_API_KEY não encontrada no Info.plist. Configure o Config.xcconfig.")
            return ""
        }
        return key
    }
}
