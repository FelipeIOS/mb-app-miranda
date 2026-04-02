import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.mbTextMuted)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Ops! Algo deu errado")
                    .font(.mbTitle)
                    .foregroundColor(.mbText)

                Text(message)
                    .font(.mbBody)
                    .foregroundColor(.mbTextSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Tentar novamente")
                }
                .font(.mbHeadline)
                .foregroundColor(.mbPrimary)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.mbGold)
                .cornerRadius(14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.mbTextMuted)

            Text("Nenhum resultado encontrado")
                .font(.mbTitle)
                .foregroundColor(.mbText)

            Text("Não encontramos exchanges disponíveis no momento.")
                .font(.mbBody)
                .foregroundColor(.mbTextSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
