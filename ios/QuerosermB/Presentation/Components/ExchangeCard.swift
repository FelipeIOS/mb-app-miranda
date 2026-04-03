import SwiftUI

struct ExchangeCard: View {
    let exchange: Exchange

    var body: some View {
        HStack(spacing: 14) {
            RemoteImageView(
                urlString: exchange.logo,
                contentMode: .fit,
                cornerRadius: 12,
                sideLength: 52
            )

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
