import UIKit
import Combine

final class ExchangeDetailViewController: UIViewController {

    // MARK: - Dependencies
    private let exchange: Exchange
    private let viewModel: ExchangeDetailViewModel
    private weak var coordinator: AppCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI — Root
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .mbPrimary
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis    = .vertical
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Header
    private let logoView   = RemoteImageView(frame: .zero)
    private let nameLabel  = UILabel()
    private let idLabel    = UILabel()

    // MARK: - Info section
    private let infoContainer = UIView()

    // MARK: - Description
    private let descriptionLabel = UILabel()
    private let seeMoreButton    = UIButton(type: .system)
    private var isDescriptionExpanded = false

    // MARK: - Currencies
    private let currenciesContainer = UIView()
    private lazy var currenciesTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle  = .singleLine
        tv.separatorColor  = .mbSurfaceAlt
        tv.separatorInset  = .zero
        tv.isScrollEnabled = false
        tv.register(CurrencyCell.self, forCellReuseIdentifier: CurrencyCell.reuseIdentifier)
        tv.rowHeight = 52
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    private var currenciesTableHeight: NSLayoutConstraint!
    private var currencies: [Currency] = []

    // MARK: - Init
    init(exchange: Exchange, viewModel: ExchangeDetailViewModel, coordinator: AppCoordinator) {
        self.exchange    = exchange
        self.viewModel   = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(exchange:viewModel:coordinator:)") }

    private enum Layout {
        static let infoSkeletonRows = 4
        static let currencySkeletonRows = 6
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupLayout()
        bindViewModel()
        Task { await viewModel.load(exchange: exchange) }
    }

    // MARK: - Setup Navigation

    private func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .mbPrimary
        appearance.titleTextAttributes = [.foregroundColor: UIColor.mbText]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Setup Layout

    private func setupLayout() {
        view.backgroundColor = .mbPrimary
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        contentStack.addArrangedSubview(buildHeader())
        contentStack.addArrangedSubview(makeSeparator())
        contentStack.addArrangedSubview(buildInfoSection())
        contentStack.addArrangedSubview(makeSeparator())
        contentStack.addArrangedSubview(buildCurrenciesSection())
        contentStack.addArrangedSubview(spacer(height: 32))
    }

    // MARK: - Header

    private func buildHeader() -> UIView {
        logoView.cornerRadiusValue = 36
        logoView.setImage(urlString: exchange.logo)
        logoView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.text      = exchange.name
        nameLabel.font      = .mbLargeTitle()
        nameLabel.textColor = .mbText
        nameLabel.accessibilityIdentifier = "exchangeDetail.title"
        nameLabel.numberOfLines = 0

        idLabel.text      = Strings.Detail.id(exchange.id)
        idLabel.font      = .mbCaption()
        idLabel.textColor = .mbTextSub

        let labelStack = UIStackView(arrangedSubviews: [nameLabel, idLabel])
        labelStack.axis    = .vertical
        labelStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [logoView, labelStack])
        row.axis      = NSLayoutConstraint.Axis.horizontal
        row.spacing   = 16
        row.alignment = UIStackView.Alignment.center
        row.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = .mbPrimary
        container.addSubview(row)

        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: 72),
            logoView.heightAnchor.constraint(equalToConstant: 72),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        return container
    }

    // MARK: - Info Section

    private func buildInfoSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .mbPrimary

        let sectionLabel = makeSectionLabel(Strings.Detail.about)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(sectionLabel)
        container.addSubview(infoContainer)

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            sectionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            sectionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            infoContainer.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 8),
            infoContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            infoContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            infoContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func showInfoLoading() {
        infoContainer.subviews.forEach { $0.removeFromSuperview() }
        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        for _ in 0..<Layout.infoSkeletonRows {
            stack.addArrangedSubview(makeInfoRowSkeleton())
        }
        infoContainer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: infoContainer.topAnchor),
            stack.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor)
        ])
    }

    private func showInfoContent(_ detail: Exchange) {
        infoContainer.subviews.forEach { $0.removeFromSuperview() }

        let outerStack = UIStackView()
        outerStack.axis    = .vertical
        outerStack.spacing = 16
        outerStack.translatesAutoresizingMaskIntoConstraints = false

        // Grid 2x2 first
        let grid = buildInfoGrid(detail)
        if let grid { outerStack.addArrangedSubview(grid) }

        // Description
        if let desc = detail.description, !desc.isEmpty {
            outerStack.addArrangedSubview(buildDescriptionBlock(desc))
        }

        // Website
        if let urlStr = detail.websiteURL, !urlStr.isEmpty {
            outerStack.addArrangedSubview(buildWebsiteButton(urlStr))
        }

        infoContainer.addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 8),
            outerStack.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -8),
            outerStack.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 16),
            outerStack.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -16)
        ])
    }

    private func showInfoError(_ message: String) {
        infoContainer.subviews.forEach { $0.removeFromSuperview() }
        let ev = ErrorView()
        ev.configure(message: message) { [weak self] in
            guard let self else { return }
            self.viewModel.triggerLoad(exchange: self.exchange)
        }
        ev.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.addSubview(ev)
        NSLayoutConstraint.activate([
            ev.topAnchor.constraint(equalTo: infoContainer.topAnchor),
            ev.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor),
            ev.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            ev.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            ev.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Description block

    private func buildDescriptionBlock(_ text: String) -> UIView {
        descriptionLabel.text          = text
        descriptionLabel.font          = .mbBody()
        descriptionLabel.textColor     = .mbTextSub
        descriptionLabel.numberOfLines = 3
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        seeMoreButton.setTitle(Strings.Detail.seeMore, for: .normal)
        seeMoreButton.setTitleColor(.mbAccent, for: .normal)
        seeMoreButton.titleLabel?.font = .mbCaption()
        seeMoreButton.addTarget(self, action: #selector(toggleDescription), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [descriptionLabel, seeMoreButton])
        stack.axis      = .vertical
        stack.spacing   = 8
        stack.alignment = .leading
        return stack
    }

    @objc private func toggleDescription() {
        isDescriptionExpanded.toggle()
        descriptionLabel.numberOfLines = isDescriptionExpanded ? 0 : 3
        seeMoreButton.setTitle(isDescriptionExpanded ? Strings.Detail.seeLess : Strings.Detail.seeMore, for: .normal)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - Info Grid

    private func buildInfoGrid(_ detail: Exchange) -> UIView? {
        var tiles: [UIView] = []
        if let v = detail.spotVolumeUSD { tiles.append(makeInfoTile(label: Strings.Detail.volume,   value: v.formatAsCompactUSD())) }
        if let d = detail.dateLaunched  { tiles.append(makeInfoTile(label: Strings.Detail.launched, value: d.formatAsMonthYear())) }
        if let m = detail.makerFee      { tiles.append(makeInfoTile(label: Strings.Detail.makerFee, value: "\(m.formattedDecimal(minFractionDigits: 2, maxFractionDigits: 12))%")) }
        if let t = detail.takerFee      { tiles.append(makeInfoTile(label: Strings.Detail.takerFee, value: "\(t.formattedDecimal(minFractionDigits: 2, maxFractionDigits: 12))%")) }
        guard !tiles.isEmpty else { return nil }

        let rows = UIStackView()
        rows.axis    = .vertical
        rows.spacing = 12

        var i = 0
        while i < tiles.count {
            let row = UIStackView()
            row.axis         = .horizontal
            row.spacing      = 12
            row.distribution = .fillEqually
            row.addArrangedSubview(tiles[i])
            if i + 1 < tiles.count { row.addArrangedSubview(tiles[i + 1]) }
            rows.addArrangedSubview(row)
            i += 2
        }
        return rows
    }

    private func makeInfoTile(label: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor    = .mbSurface
        container.layer.cornerRadius = 8

        let labelLbl       = UILabel()
        labelLbl.text      = label
        labelLbl.font      = .mbCaption()
        labelLbl.textColor = .mbTextSub

        let valueLbl           = UILabel()
        valueLbl.text          = value
        valueLbl.font          = .mbHeadline()
        valueLbl.textColor     = .mbGold
        valueLbl.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [labelLbl, valueLbl])
        stack.axis    = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
        return container
    }

    // MARK: - Website Button

    private func buildWebsiteButton(_ urlStr: String) -> UIButton {
        let btn = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.title = Strings.Detail.visitWebsite
        config.baseBackgroundColor = .mbAccent
        config.baseForegroundColor = .mbText
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        btn.configuration = config

        btn.addAction(UIAction { [weak self] _ in
            guard let url = URL(string: urlStr) else { return }
            self?.open(url: url)
        }, for: .touchUpInside)
        return btn
    }

    private func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - Currencies Section

    private func buildCurrenciesSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .mbPrimary

        let sectionLabel = makeSectionLabel(Strings.Detail.currencies)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false

        currenciesTable.dataSource = self
        currenciesTableHeight = currenciesTable.heightAnchor.constraint(equalToConstant: 0)
        currenciesTableHeight.isActive = true

        container.addSubview(sectionLabel)
        container.addSubview(currenciesContainer)

        currenciesContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            sectionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            sectionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            currenciesContainer.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 8),
            currenciesContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            currenciesContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            currenciesContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        return container
    }

    private func showCurrenciesLoading() {
        currenciesContainer.subviews.forEach { $0.removeFromSuperview() }
        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        for _ in 0..<Layout.currencySkeletonRows {
            stack.addArrangedSubview(makeInfoRowSkeleton())
        }
        currenciesContainer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: currenciesContainer.topAnchor),
            stack.bottomAnchor.constraint(equalTo: currenciesContainer.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: currenciesContainer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: currenciesContainer.trailingAnchor)
        ])
    }

    private func showCurrenciesContent(_ list: [Currency]) {
        currenciesContainer.subviews.forEach { $0.removeFromSuperview() }
        currencies = list

        if currencies.isEmpty {
            showCurrenciesEmpty()
            return
        }

        currenciesContainer.addSubview(currenciesTable)
        NSLayoutConstraint.activate([
            currenciesTable.topAnchor.constraint(equalTo: currenciesContainer.topAnchor),
            currenciesTable.bottomAnchor.constraint(equalTo: currenciesContainer.bottomAnchor),
            currenciesTable.leadingAnchor.constraint(equalTo: currenciesContainer.leadingAnchor),
            currenciesTable.trailingAnchor.constraint(equalTo: currenciesContainer.trailingAnchor)
        ])

        currenciesTable.reloadData()
        currenciesTableHeight.constant = CGFloat(currencies.count) * currenciesTable.rowHeight
    }

    private func showCurrenciesEmpty() {
        currenciesContainer.subviews.forEach { $0.removeFromSuperview() }

        let label = UILabel()
        label.text          = Strings.Detail.currenciesEmpty
        label.font          = .mbBody()
        label.textColor     = .mbTextSub
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        currenciesContainer.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: currenciesContainer.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: currenciesContainer.bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: currenciesContainer.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: currenciesContainer.trailingAnchor, constant: -16)
        ])
    }

    private func showCurrenciesError(_ message: String) {
        currenciesContainer.subviews.forEach { $0.removeFromSuperview() }
        let ev = ErrorView()
        ev.configure(message: message) { [weak self] in
            guard let self else { return }
            self.viewModel.triggerLoad(exchange: self.exchange)
        }
        ev.translatesAutoresizingMaskIntoConstraints = false
        currenciesContainer.addSubview(ev)
        NSLayoutConstraint.activate([
            ev.topAnchor.constraint(equalTo: currenciesContainer.topAnchor),
            ev.bottomAnchor.constraint(equalTo: currenciesContainer.bottomAnchor),
            ev.leadingAnchor.constraint(equalTo: currenciesContainer.leadingAnchor),
            ev.trailingAnchor.constraint(equalTo: currenciesContainer.trailingAnchor),
            ev.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$detailState
            .sink { [weak self] state in self?.applyDetailState(state) }
            .store(in: &cancellables)

        viewModel.$assetsState
            .sink { [weak self] state in self?.applyAssetsState(state) }
            .store(in: &cancellables)
    }

    private func applyDetailState(_ state: ViewState<Exchange>) {
        switch state {
        case .idle, .loading:
            showInfoLoading()
        case .success(let detail):
            showInfoContent(detail)
        case .error(let msg):
            showInfoError(msg)
        case .empty:
            break
        }
    }

    private func applyAssetsState(_ state: ViewState<[Currency]>) {
        switch state {
        case .idle, .loading:
            showCurrenciesLoading()
        case .success(let list):
            showCurrenciesContent(list)
        case .empty:
            showCurrenciesEmpty()
        case .error(let msg):
            showCurrenciesError(msg)
        }
    }

    // MARK: - Helpers

    private func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.font      = .mbTitle()
        l.textColor = .mbText
        return l
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = .mbSurfaceAlt
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    /// Duas caixas skeleton lado-a-lado (40% + 60%) com padding 16pt/8pt — equivalente ao InfoRowSkeleton do Android
    private func makeInfoRowSkeleton() -> UIView {
        let left  = skeletonView(height: 14)
        let right = skeletonView(height: 14)

        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis         = .horizontal
        row.spacing      = 16
        row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false

        let wrapper = UIView()
        wrapper.addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -8),
            row.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
            left.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.4)
        ])
        return wrapper
    }

    private func skeletonView(height: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor    = .mbSurfaceAlt
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}

// MARK: - UITableViewDataSource (currencies)

extension ExchangeDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currencies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CurrencyCell.reuseIdentifier,
            for: indexPath
        ) as? CurrencyCell else {
            fatalError("Failed to dequeue CurrencyCell")
        }
        cell.configure(with: currencies[indexPath.row])
        return cell
    }
}

