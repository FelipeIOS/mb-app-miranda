# QuerosermB — Desafio Técnico Mercado Bitcoin

App mobile para consulta de exchanges de criptomoedas via [CoinMarketCap API](https://coinmarketcap.com/api/documentation/v1/).

---

## 📱 Plataformas

| Plataforma | Stack | Status |
|---|---|---|
| iOS | Swift + SwiftUI | ✅ Implementado |
| Android | Kotlin + Jetpack Compose | 🔜 Em breve |

---

## ✨ Funcionalidades

### Tela de Lista de Exchanges
- Lista de exchanges com logo, nome, volume 24h e data de lançamento
- Shimmer loading durante o carregamento
- Pull-to-refresh para atualizar
- Estado de erro com botão "Tentar novamente"
- Estado vazio quando não há dados

### Tela de Detalhes
- Header com logo (hero animation da lista)
- ID, descrição expansível, link do website
- Maker Fee e Taker Fee
- Lista de moedas negociadas com nome e preço em USD

---

## 🏗️ Arquitetura

**Clean Architecture + MVVM**

```
Presentation (SwiftUI Views + ViewModels)
      ↓
Domain (UseCases + Entities + Repository Protocol)
      ↓
Data (Repository Impl + Remote DataSource + DTOs)
      ↓
Core (APIClient + Network + DI + Extensions)
```

### Decisões de design
- **Zero dependências externas**: URLSession, AsyncImage, Codable — tudo nativo Apple
- **Swift Concurrency**: async/await + `async let` para paralelismo real
- **Protocol-based DI**: `ExchangeRepository` como protocol, fácil de mockar em testes
- **`ViewState<T>` genérico**: `.idle`, `.loading`, `.success(T)`, `.empty`, `.error(String)`
- **API Key via xcconfig**: nunca hardcoded, fora do controle de versão
- **AppCoordinator (MVVM-C)**: `NavigationPath` tipado centraliza toda a navegação; Views não conhecem destinos concretos

### Por que SwiftUI em vez de UIKit View Code?

O enunciado menciona "View Code approach" — convenção do ecossistema iOS para UIKit programático (sem Storyboards). A escolha por **SwiftUI** foi intencional e justificada:

| Motivo | Detalhe |
|--------|---------|
| **Direção estratégica da Apple** | SwiftUI é o caminho oficial para novos projetos iOS desde 2019; UIKit entra em modo de manutenção gradual |
| **Integração nativa com async/await** | `.task {}` cancela automaticamente ao desmontar a view; sem necessidade de `AnyCancellable` ou `DispatchQueue` |
| **Previews em tempo real** | `#Preview` reduz ciclos de build/run durante o desenvolvimento |
| **Menor boilerplate** | Estados de UI (loading, erro, vazio) em ~30% menos linhas que o equivalente UIKit |
| **iOS 16+ garantido** | Todas as APIs SwiftUI utilizadas (`NavigationStack`, `NavigationPath`) são estáveis no target mínimo do projeto |

---

## 🚀 Como rodar

### Pré-requisitos
- Xcode 15+
- iOS 16+
- API Key gratuita: https://pro.coinmarketcap.com/api/v1

### Configuração da API Key

1. No terminal, a partir da pasta do repositório:

```bash
cd ios/QuerosermB
cp Config.xcconfig.example Config.xcconfig
```

2. Edite `Config.xcconfig` e troque `YOUR_API_KEY_HERE` pela sua chave do [CoinMarketCap Pro](https://pro.coinmarketcap.com/).

3. O projeto Xcode já referencia `Config.xcconfig` nas configurações Debug/Release; se o arquivo existir com `CMC_API_KEY` válido, o app compila e injeta a chave no `Info.plist` via build setting.

### Rodando o projeto

```bash
cd ios
open QuerosermB.xcodeproj
# Selecione um simulador iPhone e pressione ⌘R
```

---

## 🧪 Testes

```bash
# Via Xcode: ⌘U
# Testes cobertos:
# - GetExchangeListUseCase (success, failure, empty)
# - ExchangeListViewModel (all states)
```

---

## 📁 Estrutura do Projeto (iOS)

```
ios/QuerosermB/
├── Core/
│   ├── Network/        # APIClient, APIEndpoint, NetworkError, APIKeyProvider
│   ├── Extensions/     # Formatters (USD, datas)
│   └── DI/             # DependencyContainer
├── Data/
│   ├── Remote/
│   │   ├── DTO/        # ExchangeDTO, ExchangeAssetsDTO (Codable)
│   │   └── DataSource/ # ExchangeRemoteDataSource
│   └── Repository/     # ExchangeRepositoryImpl
├── Domain/
│   ├── Model/          # Exchange, Currency (pure Swift)
│   ├── Repository/     # ExchangeRepository (Protocol)
│   └── UseCase/        # GetExchangeListUseCase, GetExchangeDetailUseCase, GetExchangeAssetsUseCase
└── Presentation/
    ├── ExchangeList/   # ExchangeListView + ViewModel
    ├── ExchangeDetail/ # ExchangeDetailView + ViewModel
    ├── Components/     # ExchangeCard, CurrencyRowView, ShimmerView, ErrorView
    └── Theme/          # AppTheme (cores + tipografia)
```

---

## 🔐 Segurança

- `Config.xcconfig` está no `.gitignore` — a API Key nunca vai para o repositório
- Nenhuma credencial hardcoded no código fonte

---

## 👨‍💻 Autor

**Felipe Miranda** — Desafio Técnico Mercado Bitcoin