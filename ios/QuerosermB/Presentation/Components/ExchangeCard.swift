import SwiftUI

struct ExchangeCard: View {
    let exchange: Exchange
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 14) {
            // Logo com Hero Animation
            AsyncImage(url: URL(string: exchange.logo)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "building.columns.fill")
                        .foregroundColor(.mbTextSub)
                case .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.mbSurfaceAlt)
                        .shimmer()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .matchedGeometryEffect(id: "logo-\(exchange.id)", in: namespace, isSource: true)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exchange.name)
                    .font(.mbHeadline)
                    .foregroundColor(.mbText)
                    .lineLimit(1)

                if let volume = exchange.spotVolumeUSD {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Volume 24h")
                            .font(.mbCaption)
                            .foregroundColor(.mbTextSub)
                        Text(volume.formatAsCompactUSD())
                            .font(.mbBody)
                            .foregroundColor(.mbGold)
                    }
                }

                if let date = exchange.dateLaunched {
                    Text(date.formatAsMonthYear())
                        .font(.mbCaption)
                        .foregroundColor(.mbTextSub)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.mbTextMuted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mbSurface)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}
