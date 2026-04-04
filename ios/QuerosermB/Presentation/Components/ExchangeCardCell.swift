import UIKit

final class ExchangeCardCell: UITableViewCell {
    static let reuseIdentifier = "ExchangeCardCell"

    private let logoView    = RemoteImageView(frame: .zero)
    private let nameLabel   = UILabel()
    private let volumeLabel = UILabel()
    private let dateLabel   = UILabel()
    private let chevron     = UIImageView()
    private let card        = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with exchange: Exchange) {
        logoView.setImage(urlString: exchange.logo)
        nameLabel.text   = exchange.name
        volumeLabel.text = exchange.spotVolumeUSD.map { $0.formatAsCompactUSD() } ?? "—"
        dateLabel.text   = exchange.dateLaunched.map { $0.formatAsMonthYear() } ?? "—"
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.backgroundColor = .clear

        card.backgroundColor    = .mbSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds      = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        // Logo
        logoView.cornerRadiusValue = 10
        logoView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font      = .mbHeadline()
        nameLabel.textColor = .mbText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Volume
        let volIcon = makeIcon("chart.bar.fill")
        volumeLabel.font      = .mbCaption()
        volumeLabel.textColor = .mbTextSub
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false
        let volRow = hStack([volIcon, volumeLabel], spacing: 4)

        // Date
        let dateIcon = makeIcon("calendar")
        dateLabel.font      = .mbCaption()
        dateLabel.textColor = .mbTextSub
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        let dateRow = hStack([dateIcon, dateLabel], spacing: 4)

        // Info stack
        let infoStack = UIStackView(arrangedSubviews: [nameLabel, volRow, dateRow])
        infoStack.axis    = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        // Chevron
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image        = UIImage(systemName: "chevron.right", withConfiguration: config)
        chevron.tintColor    = .mbTextMuted
        chevron.contentMode  = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        card.addSubview(logoView)
        card.addSubview(infoStack)
        card.addSubview(chevron)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            logoView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            logoView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 48),
            logoView.heightAnchor.constraint(equalToConstant: 48),

            infoStack.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 12),
            infoStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            infoStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 76)
        ])
    }

    private func makeIcon(_ name: String) -> UIImageView {
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: name, withConfiguration: config))
        iv.tintColor = .mbAccent
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }

    private func hStack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal
        s.spacing = spacing
        s.alignment = .center
        return s
    }
}
