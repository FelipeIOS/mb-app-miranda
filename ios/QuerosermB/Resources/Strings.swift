import Foundation

// MARK: - Centralized localized strings
// All user-facing text lives here. Never use String(localized:) directly in UI code.

enum Strings {

    enum ExchangeList {
        static let title = String(localized: "Exchanges")
    }

    enum Detail {
        static let about           = String(localized: "Sobre")
        static let seeMore         = String(localized: "Ver_mais")
        static let seeLess         = String(localized: "Ver_menos")
        static let volume          = String(localized: "Volume_24h")
        static let launched        = String(localized: "Lançamento")
        static let makerFee        = String(localized: "Maker_Fee")
        static let takerFee        = String(localized: "Taker_Fee")
        static let currencies      = String(localized: "Moedas_Negociadas")
        static let currenciesEmpty = String(localized: "Nenhuma_moeda_listada_para_esta_exchange")

        static func id(_ value: Int) -> String {
            String(format: String(localized: "ID_%@"), "\(value)")
        }
    }

    enum Error {
        static let title    = String(localized: "Ops_Algo_deu_errado")
        static let retry    = String(localized: "Tentar_novamente")
        static let loadMore = String(localized: "Nao_foi_possivel_carregar_mais")
        static let unknown  = String(localized: "Erro_desconhecido")
        static let detail   = String(localized: "Erro_ao_carregar_detalhes")
        static let assets   = String(localized: "Erro_ao_carregar_moedas")
    }

    enum Empty {
        static let title   = String(localized: "Nenhum_resultado_encontrado")
        static let message = String(localized: "Nao_encontramos_exchanges_disponiveis")
    }

    enum Network {
        static let invalidURL      = String(localized: "URL_invalida")
        static let invalidResponse = String(localized: "Resposta_invalida_do_servidor")
        static let decoding        = String(localized: "Erro_ao_processar_os_dados")
        static let noConnection    = String(localized: "Sem_conexao_com_a_internet")

        static func serverError(code: Int) -> String {
            String(format: String(localized: "Erro_no_servidor_codigo"), code)
        }
    }
}
