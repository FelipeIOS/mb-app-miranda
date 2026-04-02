import SwiftUI

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    // Evita "Failed to create Wx0 image slot" quando o layout ainda não tem altura.
                    if geo.size.width > 1, geo.size.height > 1 {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear,                      location: 0),
                                .init(color: Color.white.opacity(0.15),   location: 0.45),
                                .init(color: Color.white.opacity(0.25),   location: 0.5),
                                .init(color: Color.white.opacity(0.15),   location: 0.55),
                                .init(color: .clear,                      location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2, height: geo.size.height)
                        .offset(x: geo.size.width * phase)
                    }
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4).repeatForever(autoreverses: false)
                ) { phase = 1 }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card (placeholder de loading)
struct ExchangeCardSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mbSurfaceAlt)
                .frame(width: 52, height: 52)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.mbSurfaceAlt)
                    .frame(height: 14)
                    .shimmer()
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.mbSurfaceAlt)
                    .frame(width: 120, height: 12)
                    .shimmer()
            }
            Spacer()
        }
        .padding(16)
        .background(Color.mbSurface)
        .cornerRadius(16)
    }
}

#Preview {
    ZStack {
        Color.mbPrimary.ignoresSafeArea()
        VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                ExchangeCardSkeleton()
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
