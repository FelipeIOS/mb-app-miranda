import UIKit

final class ExchangeCardCell: UITableViewCell {
    static let reuseIdentifier = "ExchangeCardCell"

    private let logoView    = RemoteImageView(frame: .zero)
    private let nameLabel   = UILabel()
    private let volumeLabel = UILabel()
    private let dateLabel   = UILabel()
    private let chevron     = UIImageView()
    private let separator   = UIView()

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
        nameLabel.text = exchange.name
        if let volume = exchange.spotVolumeUSD {
            volumeLabel.text = volume.formatAsCompactUSD()
            volumeLabel.isHidden = false
        } else {
            volumeLabel.isHidden = true
        }
        if let date = exchange.dateLaunched {
            dateLabel.text = date.formatAsMonthYear()
            dateLabel.isHidden = false
        } else {
            dateLabel.isHidden = true
        }
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.backgroundColor = .clear

        imageView?.removeFromSuperview()
        textLabel?.removeFromSuperview()
        detailTextLabel?.removeFromSuperview()

        // Logo — circle
        logoView.cornerRadiusValue = 24
        logoView.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font      = .mbHeadline()
        nameLabel.textColor = .mbText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Volume — gold, hidden until configured
        volumeLabel.font      = .mbCaption()
        volumeLabel.textColor = .mbGold
        volumeLabel.isHidden  = true
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Date — textSub, hidden until configured
        dateLabel.font      = .mbCaption()
        dateLabel.textColor = .mbTextSub
        dateLabel.isHidden  = true
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        // Info stack
        let infoStack = UIStackView(arrangedSubviews: [nameLabel, volumeLabel, dateLabel])
        infoStack.axis    = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        // Chevron
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image       = UIImage(systemName: "chevron.right", withConfiguration: config)
        chevron.tintColor   = .mbTextSub
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        // Separator line
        separator.backgroundColor = .mbSurfaceAlt
        separator.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(logoView)
        contentView.addSubview(infoStack)
        contentView.addSubview(chevron)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            logoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            logoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 48),
            logoView.heightAnchor.constraint(equalToConstant: 48),
            logoView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            logoView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            infoStack.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 12),
            infoStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            infoStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72)
        ])
    }
}
