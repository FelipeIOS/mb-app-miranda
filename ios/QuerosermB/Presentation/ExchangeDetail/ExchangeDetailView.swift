import SwiftUI

struct ExchangeDetailView: View {
    let exchange: Exchange

    @StateObject private var viewModel: ExchangeDetailViewModel
    @Environment(\.openURL) private var openURL
    @State private var descriptionExpanded = false

    init(exchange: Exchange, viewModel: ExchangeDetailViewModel) {
        self.exchange = exchange
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.mbPrimary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header fora do ScrollView: evita bug do `matchedGeometryEffect` (logo “flutuando” sobre o conteúdo).
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(Color.mbPrimary)
                    .zIndex(1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .background(Color.mbSurfaceAlt)
                            .padding(.bottom, 20)
                            .padding(.horizontal, 20)

                        infoSection
                            .padding(.horizontal, 20)

                        Divider()
                            .background(Color.mbSurfaceAlt)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)

                        currenciesSection
                            .padding(.horizontal, 20)

                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.mbPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(exchange: exchange) }
    }

    // MARK: - Header (logo grande + nome)
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            logoView

            VStack(alignment: .leading, spacing: 4) {
                Text(exchange.name)
                    .font(.mbLargeTitle)
                    .foregroundColor(.mbText)
                    .accessibilityIdentifier("exchangeDetail.title")

                Text("ID: \(exchange.id)")
                    .font(.mbCaption)
                    .foregroundColor(.mbTextSub)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var logoView: some View {
        RemoteImageView(
            urlString: exchange.logo,
            contentMode: .fill,
            cornerRadius: 16,
            sideLength: 72
        )
    }

    // MARK: - Info Section
    @ViewBuilder
    private var infoSection: some View {
        switch viewModel.detailState {
        case .loading:
            infoSkeleton
        case .success(let detail):
            infoContent(detail)
        case .error(let msg):
            ErrorView(message: msg, embedded: true) {
                viewModel.triggerLoad(exchange: exchange)
            }
            .frame(minHeight: 200)
        default:
            EmptyView()
        }
    }

    private var infoSkeleton: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mbSurfaceAlt)
                    .frame(height: 14)
                    .shimmer()
            }
        }
    }

    private func infoContent(_ detail: Exchange) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Descrição expansível
            if let desc = detail.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "Sobre")
                    Text(desc)
                        .font(.mbBody)
                        .foregroundColor(.mbTextSub)
                        .lineLimit(descriptionExpanded ? nil : 3)

                    Button(descriptionExpanded ? "Ver menos" : "Ver mais") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            descriptionExpanded.toggle()
                        }
                    }
                    .font(.mbCaption)
                    .foregroundColor(.mbAccent)
                }
            }

            // Grid de dados
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let volume = detail.spotVolumeUSD {
                    InfoTile(label: "Volume 24h", value: volume.formatAsCompactUSD(), icon: "chart.bar.fill")
                }
                if let date = detail.dateLaunched {
                    InfoTile(label: "Lançamento", value: date.formatAsMonthYear(), icon: "calendar")
                }
                if let maker = detail.makerFee {
                    InfoTile(label: "Maker Fee", value: "\(maker)%", icon: "arrow.up.right")
                }
                if let taker = detail.takerFee {
                    InfoTile(label: "Taker Fee", value: "\(taker)%", icon: "arrow.down.left")
                }
            }

            // Website link
            if let websiteStr = detail.websiteURL, let url = URL(string: websiteStr) {
                Button {
                    openURL(url)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text(websiteStr)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.mbBody)
                    .foregroundColor(.mbAccent)
                    .padding(14)
                    .background(Color.mbSurface)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Currencies Section
    @ViewBuilder
    private var currenciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Moedas Negociadas")

            switch viewModel.assetsState {
            case .loading:
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.mbSurfaceAlt)
                        .frame(height: 44)
                        .shimmer()
                }
            case .success(let currencies):
                LazyVStack(spacing: 0) {
                    // O mesmo `crypto_id` pode aparecer várias vezes (carteiras diferentes); o índice é único para o ForEach.
                    ForEach(Array(currencies.enumerated()), id: \.offset) { index, currency in
                        CurrencyRowView(currency: currency)
                        if index < currencies.count - 1 {
                            Divider().background(Color.mbSurfaceAlt)
                        }
                    }
                }
                .background(Color.mbSurface)
                .cornerRadius(16)
            case .empty:
                VStack(spacing: 12) {
                    Image(systemName: "bitcoinsign.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.mbTextMuted)
                    Text("Nenhuma moeda listada para esta exchange.")
                        .font(.mbBody)
                        .foregroundColor(.mbTextSub)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 8)
            case .error(let msg):
                ErrorView(message: msg, embedded: true) {
                    viewModel.triggerLoad(exchange: exchange)
                }
                .frame(minHeight: 200)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Sub-components

struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.mbCaption)
            .foregroundColor(.mbTextSub)
            .kerning(1.2)
    }
}

struct InfoTile: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(.mbAccent)
                Text(label)
                    .font(.mbCaption)
                    .foregroundColor(.mbTextSub)
            }
            Text(value)
                .font(.mbHeadline)
                .foregroundColor(.mbText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.mbSurface)
        .cornerRadius(14)
    }
}
