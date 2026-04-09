import UIKit

// MARK: - CurrencyRowView (UIView reutilizável no StackView do detail)

final class CurrencyRowView: UIView {

    private let badgeView   = UIView()
    private let badgeLabel  = UILabel()
    private let nameLabel   = UILabel()
    private let symbolLabel = UILabel()
    private let priceLabel  = UILabel()
    private let separator   = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with currency: Currency) {
        badgeLabel.text  = String(currency.symbol.prefix(3))
        nameLabel.text   = currency.name
        symbolLabel.text = currency.symbol
        priceLabel.text  = currency.priceUSD.map { $0.formatAsUSD() } ?? "—"
    }

    private func setup() {
        backgroundColor = .clear

        badgeView.backgroundColor    = .mbAccent
        badgeView.layer.cornerRadius = 20
        badgeView.translatesAutoresizingMaskIntoConstraints = false

        badgeLabel.font          = .mbCaption()
        badgeLabel.textColor     = .mbText
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(badgeLabel)

        nameLabel.font      = .mbHeadline()
        nameLabel.textColor = .mbText

        symbolLabel.font      = .mbCaption()
        symbolLabel.textColor = .mbTextSub

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, symbolLabel])
        nameStack.axis    = .vertical
        nameStack.spacing = 2
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font          = .mbBody()
        priceLabel.textColor     = .mbText
        priceLabel.textAlignment = .right
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = .mbSurfaceAlt
        separator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(badgeView)
        addSubview(nameStack)
        addSubview(priceLabel)
        addSubview(separator)

        NSLayoutConstraint.activate([
            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            badgeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            badgeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 40),
            badgeView.heightAnchor.constraint(equalToConstant: 40),

            nameStack.leadingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: 12),
            nameStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameStack.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),

            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            priceLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),

            heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
    }
}

// MARK: - CurrencyCell (wrapper para UITableView — não usado no detail, mantido para compatibilidade futura)

final class CurrencyCell: UITableViewCell {
    static let reuseIdentifier = "CurrencyCell"

    private let rowView = CurrencyRowView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        rowView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowView)
        NSLayoutConstraint.activate([
            rowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with currency: Currency) {
        rowView.configure(with: currency)
    }
}
