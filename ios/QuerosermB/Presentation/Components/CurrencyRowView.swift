import SwiftUI

struct CurrencyRowView: View {
    let currency: Currency

    var body: some View {
        HStack {
            // Ícone / Símbolo
            ZStack {
                Circle()
                    .fill(Color.mbAccent.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text(currency.symbol.prefix(3))
                    .font(.mbCaption)
                    .fontWeight(.bold)
                    .foregroundColor(.mbAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(currency.name)
                    .font(.mbBody)
                    .foregroundColor(.mbText)
                    .lineLimit(1)
                Text(currency.symbol)
                    .font(.mbCaption)
                    .foregroundColor(.mbTextSub)
            }

            Spacer()

            // Preço
            if let price = currency.priceUSD {
                Text(price.formatAsUSD())
                    .font(.mbMono)
                    .foregroundColor(.mbGold)
            } else {
                Text("—")
                    .font(.mbMono)
                    .foregroundColor(.mbTextMuted)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}
