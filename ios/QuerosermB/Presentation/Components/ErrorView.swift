import SwiftUI

struct ErrorView: View {
    let message: String
    /// Quando `true` (dentro de `ScrollView` / altura fixa), não usa `maxHeight: .infinity` para evitar layout inválido.
    var embedded: Bool = false
    let onRetry: () -> Void

    @State private var pulseIcon = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(.mbTextMuted)
                .scaleEffect(pulseIcon ? 1.08 : 1.0)
                .opacity(pulseIcon ? 0.75 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        pulseIcon = true
                    }
                }

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
        .frame(maxWidth: .infinity)
        .frame(maxHeight: embedded ? nil : .infinity)
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
