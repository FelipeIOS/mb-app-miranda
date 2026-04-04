import UIKit

// MARK: - ErrorView

final class ErrorView: UIView {

    private let iconImageView  = UIImageView()
    private let titleLabel     = UILabel()
    private let messageLabel   = UILabel()
    private let retryButton    = UIButton(type: .system)
    private var onRetry: (() -> Void)?
    private var pulseAnimation: CABasicAnimation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(message: String, onRetry: @escaping () -> Void) {
        messageLabel.text = message
        self.onRetry = onRetry
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startPulse() } else { stopPulse() }
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear

        let config = UIImage.SymbolConfiguration(pointSize: 52, weight: .light)
        iconImageView.image = UIImage(systemName: "wifi.exclamationmark", withConfiguration: config)
        iconImageView.tintColor = .mbTextMuted
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Ops! Algo deu errado"
        titleLabel.font = .mbTitle()
        titleLabel.textColor = .mbText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = .mbBody()
        messageLabel.textColor = .mbTextSub
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Tentar novamente"
        buttonConfig.image = UIImage(systemName: "arrow.clockwise")
        buttonConfig.imagePadding = 8
        buttonConfig.baseBackgroundColor = .mbGold
        buttonConfig.baseForegroundColor = .mbPrimary
        buttonConfig.cornerStyle = .medium
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        retryButton.configuration = buttonConfig
        retryButton.titleLabel?.font = .mbHeadline()
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.setCustomSpacing(8, after: titleLabel)
        stack.setCustomSpacing(20, after: iconImageView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            messageLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -64)
        ])
    }

    @objc private func retryTapped() { onRetry?() }

    // MARK: - Pulse Animation

    private func startPulse() {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 1.0
        anim.toValue = 0.65
        anim.duration = 1.1
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconImageView.layer.add(anim, forKey: "pulse")
    }

    private func stopPulse() {
        iconImageView.layer.removeAnimation(forKey: "pulse")
    }
}

// MARK: - EmptyStateView

final class EmptyStateView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        let config = UIImage.SymbolConfiguration(pointSize: 52, weight: .light)
        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass", withConfiguration: config))
        iconView.tintColor = .mbTextMuted
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = "Nenhum resultado encontrado"
        titleLabel.font = .mbTitle()
        titleLabel.textColor = .mbText
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = "Não encontramos exchanges disponíveis no momento."
        messageLabel.font = .mbBody()
        messageLabel.textColor = .mbTextSub
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            messageLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -64)
        ])
    }
}
