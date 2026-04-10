# QuerosermB — Desafio Técnico Mercado Bitcoin

App mobile para consulta de exchanges de criptomoedas via [CoinMarketCap API](https://coinmarketcap.com/api/documentation/v1/).

---

## Plataformas

| Plataforma | Stack | Status |
|---|---|---|
| iOS | Swift + UIKit (View Code) + Combine | ✅ Implementado |
| Android | Kotlin + Jetpack Compose + Hilt | ✅ Implementado |

---

## Funcionalidades

### Tela de Lista de Exchanges
- Lista de exchanges com logo, nome e volume 24h
- Paginação infinita (load more automático)
- Shimmer loading durante o carregamento
- Pull-to-refresh para atualizar
- Estado de erro com botão "Tentar novamente"
- Estado vazio quando não há dados

### Tela de Detalhes
- Header com logo da exchange
- ID, descrição expansível, link do website
- Volume 24h, data de lançamento, Maker Fee e Taker Fee
- Lista de moedas negociadas com nome e preço em USD
- Cache com TTL de 90s (evita requisições repetidas)

---

## Arquitetura

**Clean Architecture + MVVM** em ambas as plataformas.

```
Presentation  (Views + ViewModels)
      ↓
Domain        (UseCases + Models + Repository Protocol)
      ↓
Data          (Repository Impl + RemoteDataSource + DTOs)
      ↓
Core          (Network + Cache + DI + Formatters)
```

---

## Como rodar

### Pré-requisitos comuns
- API Key gratuita: https://pro.coinmarketcap.com/api/v1

---

### iOS

**Requisitos:** Xcode 15+ · iOS 16+

#### Configuração da API Key

```bash
cd ios/QuerosermB
cp Config.xcconfig.example Config.xcconfig
```

Edite `Config.xcconfig` e substitua `YOUR_API_KEY_HERE` pela sua chave.

#### Build e execução

```bash
cd ios
xcodegen generate       # gera o .xcodeproj
open QuerosermB.xcodeproj
# Selecione um simulador iPhone e pressione ⌘R
```

#### Testes

```bash
# Via Xcode: ⌘U
# Ou via terminal:
xcodebuild test -project ios/QuerosermB.xcodeproj -scheme QuerosermB -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

### Android

**Requisitos:** Android Studio Hedgehog+ · Android SDK 26+ · JDK 17+

#### Configuração da API Key

Crie o arquivo `android/local.properties` (se não existir) e adicione:

```properties
CMC_API_KEY=sua_chave_aqui
```

> O arquivo `android/local.properties` já está no `.gitignore` — a chave nunca vai para o repositório.

#### Build e execução

```bash
cd android
./gradlew installDebug
```

Ou abra a pasta `android/` no Android Studio e execute via ▶.

#### Testes

```bash
cd android
./gradlew test                        # unit tests
./gradlew connectedAndroidTest        # instrumented tests (requer dispositivo/emulador)
```

---

## Segurança

- iOS: `Config.xcconfig` no `.gitignore` — API Key nunca versionada
- Android: `local.properties` no `.gitignore` — API Key nunca versionada
- Nenhuma credencial hardcoded no código fonte

---

## Autor

**Felipe Miranda** — Desafio Técnico Mercado Bitcoin
