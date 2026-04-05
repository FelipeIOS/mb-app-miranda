import UIKit
import Combine

final class ExchangeListViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: ExchangeListViewModel
    private weak var coordinator: AppCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .mbPrimary
        tv.separatorStyle  = .none
        tv.register(ExchangeCardCell.self, forCellReuseIdentifier: ExchangeCardCell.reuseIdentifier)
        tv.register(ExchangeCardSkeletonCell.self, forCellReuseIdentifier: ExchangeCardSkeletonCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 88
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = .mbGold
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    private lazy var errorView: ErrorView = {
        let v = ErrorView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var emptyView: EmptyStateView = {
        let v = EmptyStateView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var loadMoreSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .mbGold
        s.hidesWhenStopped = true
        s.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56)
        return s
    }()

    // MARK: - DiffableDataSource
    private enum Section { case skeleton, exchanges }

    private enum Item: Hashable {
        case skeleton(UUID)
        case exchange(Exchange)
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    private typealias Snapshot   = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!

    // MARK: - Init
    init(viewModel: ExchangeListViewModel, coordinator: AppCoordinator) {
        self.viewModel   = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(viewModel:coordinator:)") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupLayout()
        setupDataSource()
        bindViewModel()
        tableView.delegate = self

        Task { await viewModel.loadInitialListIfNeeded() }
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = Strings.ExchangeList.title
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .mbPrimary
        appearance.titleTextAttributes      = [.foregroundColor: UIColor.mbText]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.mbText]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance
    }

    private func setupLayout() {
        view.backgroundColor = .mbPrimary
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        view.addSubview(errorView)
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupDataSource() {
        dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .skeleton:
                return tableView.dequeueReusableCell(
                    withIdentifier: ExchangeCardSkeletonCell.reuseIdentifier,
                    for: indexPath
                ) as! ExchangeCardSkeletonCell
            case .exchange(let exchange):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ExchangeCardCell.reuseIdentifier,
                    for: indexPath
                ) as! ExchangeCardCell
                cell.configure(with: exchange)
                cell.accessibilityIdentifier = "exchangeList.cell.\(exchange.id)"
                return cell
            }
        }
        dataSource.defaultRowAnimation = .fade
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$state
            .sink { [weak self] state in self?.apply(state: state) }
            .store(in: &cancellables)

        viewModel.$isLoadingMore
            .sink { [weak self] loading in
                guard let self else { return }
                if loading {
                    loadMoreSpinner.startAnimating()
                    tableView.tableFooterView = loadMoreSpinner
                } else {
                    loadMoreSpinner.stopAnimating()
                    tableView.tableFooterView = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - State

    private func apply(state: ViewState<[Exchange]>) {
        refreshControl.endRefreshing()
        errorView.isHidden = true
        emptyView.isHidden = true

        switch state {
        case .idle, .loading:
            showSkeleton()

        case .success(let exchanges):
            showExchanges(exchanges)

        case .empty:
            showEmpty()

        case .error(let message):
            tableView.isHidden = true
            errorView.isHidden = false
            errorView.configure(message: message) { [weak self] in
                Task { await self?.viewModel.refresh() }
            }
        }
    }

    private func showSkeleton() {
        tableView.isHidden = false
        var snap = Snapshot()
        snap.appendSections([.skeleton])
        snap.appendItems((0..<8).map { _ in Item.skeleton(UUID()) }, toSection: .skeleton)
        dataSource.apply(snap, animatingDifferences: false)
    }

    private func showExchanges(_ exchanges: [Exchange]) {
        tableView.isHidden = false
        var snap = Snapshot()
        snap.appendSections([.exchanges])
        snap.appendItems(exchanges.map { Item.exchange($0) }, toSection: .exchanges)
        Task { await dataSource.apply(snap, animatingDifferences: true) }
    }

    private func showEmpty() {
        tableView.isHidden = true
        emptyView.isHidden = false
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        Task { await viewModel.refresh() }
    }
}

// MARK: - UITableViewDelegate

extension ExchangeListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case .exchange(let exchange) = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinator?.showDetail(for: exchange)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .success(let exchanges) = viewModel.state,
              indexPath.row == exchanges.count - 1 else { return }
        Task { await viewModel.loadMore() }
    }
}
