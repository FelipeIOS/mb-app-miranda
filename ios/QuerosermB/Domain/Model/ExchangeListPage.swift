import Foundation

/// Uma página da lista de exchanges (`/v1/exchange/map` + `/v1/exchange/info`).
struct ExchangeListPage: Equatable {
    let items: [Exchange]
    /// `true` quando a página veio “cheia” — pode existir próxima página no mapa.
    let hasMore: Bool
    /// Próximo valor de `start` para o próximo `/exchange/map` (baseado na quantidade retornada pelo map).
    let nextStart: Int
}
