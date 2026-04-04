import UIKit

final class ExchangeCardSkeletonCell: UITableViewCell, Shimmerable {
    static let reuseIdentifier = "ExchangeCardSkeletonCell"

    private let card = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Reatualiza o layer de shimmer ao redimensionar
        stopShimmer()
        startShimmer()
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

        // Logo placeholder
        let logo = skeletonView(width: 48, height: 48, cornerRadius: 10)

        // Lines
        let line1 = skeletonView(height: 14, cornerRadius: 4)
        let line2 = skeletonView(height: 11, cornerRadius: 4)
        let line3 = skeletonView(height: 11, cornerRadius: 4)

        let lineStack = UIStackView(arrangedSubviews: [line1, line2, line3])
        lineStack.axis    = .vertical
        lineStack.spacing = 6
        lineStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(logo)
        card.addSubview(lineStack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.heightAnchor.constraint(equalToConstant: 76),

            logo.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            logo.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            lineStack.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: 12),
            lineStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -40),
            lineStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            line1.widthAnchor.constraint(equalTo: lineStack.widthAnchor, multiplier: 0.6),
            line2.widthAnchor.constraint(equalTo: lineStack.widthAnchor, multiplier: 0.8),
            line3.widthAnchor.constraint(equalTo: lineStack.widthAnchor, multiplier: 0.5)
        ])
    }

    private func skeletonView(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 4) -> UIView {
        let v = UIView()
        v.backgroundColor    = .mbSurfaceAlt
        v.layer.cornerRadius = cornerRadius
        v.translatesAutoresizingMaskIntoConstraints = false
        if let w = width {
            v.widthAnchor.constraint(equalToConstant: w).isActive = true
        }
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}
