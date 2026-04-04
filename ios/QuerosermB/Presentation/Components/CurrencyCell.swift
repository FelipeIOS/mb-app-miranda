import UIKit

final class CurrencyCell: UITableViewCell {
    static let reuseIdentifier = "CurrencyCell"

    private let badgeView   = UIView()
    private let badgeLabel  = UILabel()
    private let nameLabel   = UILabel()
    private let symbolLabel = UILabel()
    private let priceLabel  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with currency: Currency) {
        let sym = String(currency.symbol.prefix(3))
        badgeLabel.text = sym
        nameLabel.text   = currency.name
        symbolLabel.text = currency.symbol
        priceLabel.text  = currency.priceUSD.map { $0.formatAsUSD() } ?? "—"
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle  = .none

        // Badge
        badgeView.backgroundColor    = .mbAccent.withAlphaComponent(0.2)
        badgeView.layer.cornerRadius = 8
        badgeView.translatesAutoresizingMaskIntoConstraints = false

        badgeLabel.font          = .mbCaption()
        badgeLabel.textColor     = .mbAccent
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)

        // Name + symbol stack
        nameLabel.font      = .mbBody()
        nameLabel.textColor = .mbText
        symbolLabel.font    = .mbCaption()
        symbolLabel.textColor = .mbTextSub

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, symbolLabel])
        nameStack.axis    = .vertical
        nameStack.spacing = 2
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        // Price
        priceLabel.font          = .mbMono()
        priceLabel.textColor     = .mbText
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(badgeView)
        contentView.addSubview(nameStack)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            badgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            badgeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 40),
            badgeView.heightAnchor.constraint(equalToConstant: 28),

            nameStack.leadingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: 12),
            nameStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameStack.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),

            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }
}
