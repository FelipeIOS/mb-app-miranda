import SwiftUI
import UIKit

// MARK: - Session com cache em disco (AsyncImage não re-tenta e compartilha cache agressivo limitado)

enum ExchangeImageSession {
    static let shared: URLSession = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ExchangeLogos", isDirectory: true)
        if let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let cache = URLCache(
            memoryCapacity: 40 * 1024 * 1024,
            diskCapacity: 120 * 1024 * 1024,
            directory: directory
        )
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpMaximumConnectionsPerHost = 8
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
}

/// Carrega imagem remota com cache HTTP + novas tentativas em falha de rede/HTTP.
struct RemoteImageView: View {
    let urlString: String
    var contentMode: ContentMode = .fit
    var cornerRadius: CGFloat = 12
    /// Tamanho fixo (lista e detalhe); `nil` = só clip (evitar layout zero).
    var sideLength: CGFloat?

    @State private var uiImage: UIImage?
    @State private var loadFailed = false
    /// Só aplica resultado se ainda for o carregamento atual (evita logo errada ao reutilizar célula / mudar URL).
    @State private var activeLoadID = UUID()

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loadFailed {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: sideLength.map { min($0 * 0.45, 28) } ?? 22))
                    .foregroundColor(.mbTextSub)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.mbSurfaceAlt)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.mbSurfaceAlt)
                    .shimmer()
            }
        }
        .modifier(OptionalSquareFrame(side: sideLength))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: urlString) {
            let loadID = UUID()
            activeLoadID = loadID
            await load(loadID: loadID)
        }
    }

    @MainActor
    private func load(loadID: UUID) async {
        uiImage = nil
        loadFailed = false

        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            guard activeLoadID == loadID else { return }
            loadFailed = true
            return
        }

        let maxAttempts = 3
        for attempt in 1 ... maxAttempts {
            try? Task.checkCancellation()
            do {
                let (data, response) = try await ExchangeImageSession.shared.data(from: url)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse,
                      (200 ... 299).contains(http.statusCode)
                else {
                    throw URLError(.badServerResponse)
                }
                // Logos são pequenos: decode síncrono evita Task.detached sem cancelamento e troca de logo ao scroll.
                guard let decoded = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                try Task.checkCancellation()
                guard activeLoadID == loadID else { return }
                uiImage = decoded
                return
            } catch {
                if attempt < maxAttempts {
                    let ns = UInt64(150_000_000 + 150_000_000 * attempt)
                    try? await Task.sleep(nanoseconds: ns)
                }
            }
        }
        guard activeLoadID == loadID else { return }
        loadFailed = true
    }
}

private struct OptionalSquareFrame: ViewModifier {
    let side: CGFloat?

    func body(content: Content) -> some View {
        if let side {
            content.frame(width: side, height: side)
        } else {
            content
        }
    }
}
