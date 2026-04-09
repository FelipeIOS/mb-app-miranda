import UIKit

final class ExchangeCardSkeletonCell: UITableViewCell, Shimmerable {
    static let reuseIdentifier = "ExchangeCardSkeletonCell"

    private let separator = UIView()

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
        stopShimmer()
        startShimmer()
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.backgroundColor = .clear

        imageView?.removeFromSuperview()
        textLabel?.removeFromSuperview()
        detailTextLabel?.removeFromSuperview()

        // Circle logo placeholder
        let logo = skeletonView(width: 48, height: 48, cornerRadius: 24)

        // Name line (55% width)
        let line1 = skeletonView(height: 16, cornerRadius: 4)
        // Volume line (35% width)
        let line2 = skeletonView(height: 12, cornerRadius: 4)

        let lineStack = UIStackView(arrangedSubviews: [line1, line2])
        lineStack.axis      = .vertical
        lineStack.alignment = .leading
        lineStack.spacing   = 8
        lineStack.translatesAutoresizingMaskIntoConstraints = false

        // Right placeholder box
        let rightBox = skeletonView(width: 80, height: 14, cornerRadius: 4)

        separator.backgroundColor = .mbSurfaceAlt
        separator.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(logo)
        contentView.addSubview(lineStack)
        contentView.addSubview(rightBox)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            logo.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            logo.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            lineStack.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: 12),
            lineStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            lineStack.trailingAnchor.constraint(equalTo: rightBox.leadingAnchor, constant: -12),

            line1.widthAnchor.constraint(equalTo: lineStack.widthAnchor, multiplier: 0.55),
            line2.widthAnchor.constraint(equalTo: lineStack.widthAnchor, multiplier: 0.35),

            rightBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightBox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentView.heightAnchor.constraint(equalToConstant: 72)
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
