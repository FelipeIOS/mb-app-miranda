import UIKit

// MARK: - URLSession dedicado (cache 40MB mem + 120MB disco)

enum ExchangeImageSession {
    static let shared: URLSession = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ExchangeLogos", isDirectory: true)
        if let dir = directory {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
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

// MARK: - RemoteImageView

/// UIImageView com carregamento assíncrono, cache HTTP, 3 tentativas e fallback.
final class RemoteImageView: UIImageView {

    private var activeLoadID = UUID()
    private var loadTask: Task<Void, Never>?

    var cornerRadiusValue: CGFloat = 12 {
        didSet { layer.cornerRadius = cornerRadiusValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = cornerRadiusValue
        backgroundColor = .mbSurfaceAlt
    }

    func setImage(urlString: String) {
        loadTask?.cancel()
        let loadID = UUID()
        activeLoadID = loadID
        image = nil
        backgroundColor = .mbSurfaceAlt

        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            showFallback()
            return
        }

        loadTask = Task { [weak self] in
            await self?.load(url: url, loadID: loadID)
        }
    }

    private func load(url: URL, loadID: UUID) async {
        let maxAttempts = 3
        for attempt in 1 ... maxAttempts {
            try? Task.checkCancellation()
            do {
                let (data, response) = try await ExchangeImageSession.shared.data(from: url)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode)
                else { throw URLError(.badServerResponse) }
                guard let decoded = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                try Task.checkCancellation()
                guard activeLoadID == loadID else { return }
                await MainActor.run { [weak self] in
                    self?.image = decoded
                    self?.backgroundColor = .clear
                }
                return
            } catch {
                if attempt < maxAttempts {
                    let ns = UInt64(150_000_000 * attempt)
                    try? await Task.sleep(nanoseconds: ns)
                }
            }
        }
        guard activeLoadID == loadID else { return }
        await MainActor.run { [weak self] in self?.showFallback() }
    }

    private func showFallback() {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        image = UIImage(systemName: "building.columns.fill", withConfiguration: config)
        tintColor = .mbTextSub
        backgroundColor = .mbSurfaceAlt
        contentMode = .center
    }

    deinit { loadTask?.cancel() }
}
