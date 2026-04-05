import UIKit
import Combine

final class ExchangeListViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: ExchangeListViewModel
    private weak var coordinator: AppCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Search
    private var searchText: String = ""
    private let searchSubject = PassthroughSubject<String, Never>()
    private var allExchanges: [Exchange] = []
    private var filteredExchanges: [Exchange] = []

    // MARK: - UI
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Nome, slug ou ID"
        sc.searchBar.barStyle = .black
        sc.searchBar.tintColor = .mbAccent
        sc.searchBar.searchTextField.textColor = .mbText
        sc.searchBar.searchTextField.font = .mbBody()
        sc.searchBar.searchTextField.backgroundColor = .mbSurface
        sc.searchBar.searchTextField.accessibilityIdentifier = "exchangeSearch.field.query"
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .mbPrimary
        tv.separatorStyle  = .none
        tv.register(ExchangeCardCell.self, forCellReuseIdentifier: ExchangeCardCell.reuseIdentifier)
        tv.register(ExchangeCardSkeletonCell.self, forCellReuseIdentifier: ExchangeCardSkeletonCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 88
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tv.keyboardDismissMode = .onDrag
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

    private lazy var emptySearchView: UIView = {
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 48, weight: .light)))
        icon.tintColor = .mbTextMuted
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "Nenhum resultado"
        title.font = .mbTitle()
        title.textColor = .mbText
        title.textAlignment = .center
        title.accessibilityIdentifier = "exchangeSearch.empty.title"

        let sub = UILabel()
        sub.font = .mbBody()
        sub.textColor = .mbTextSub
        sub.textAlignment = .center
        sub.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, title, sub])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.backgroundColor = .mbPrimary
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32)
        ])
        container.isHidden = true
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
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
        title = "Exchanges"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .mbPrimary
        appearance.titleTextAttributes       = [.foregroundColor: UIColor.mbText]
        appearance.largeTitleTextAttributes  = [.foregroundColor: UIColor.mbText]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        // Evita conflitos de Auto Layout no nav bar (ButtonWrapper width == 0) ao combinar
        // large titles + search na mesma faixa horizontal.
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        definesPresentationContext = true
    }

    private func setupLayout() {
        view.backgroundColor = .mbPrimary

        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        view.addSubview(errorView)
        view.addSubview(emptyView)
        view.addSubview(emptySearchView)

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
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptySearchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptySearchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptySearchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptySearchView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                    self.loadMoreSpinner.startAnimating()
                    self.tableView.tableFooterView = self.loadMoreSpinner
                } else {
                    self.loadMoreSpinner.stopAnimating()
                    self.tableView.tableFooterView = nil
                }
            }
            .store(in: &cancellables)

        // Debounce: evita processar cada keystroke individualmente
        searchSubject
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.searchText = text
                self?.applyFilter()
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
            allExchanges = []
            showSkeleton()

        case .success(let exchanges):
            let isFirstLoad = allExchanges.isEmpty
            allExchanges = exchanges
            applyFilter(animated: isFirstLoad)

        case .empty:
            allExchanges = []
            showEmpty()

        case .error(let message):
            allExchanges = []
            tableView.isHidden = true
            errorView.isHidden = false
            errorView.configure(message: message) { [weak self] in
                Task { await self?.viewModel.refresh() }
            }
        }
    }

    private func applyFilter(animated: Bool = false) {
        filteredExchanges = ExchangeListViewModel.filterExchanges(allExchanges, query: searchText)

        let isSearching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let noResults   = isSearching && filteredExchanges.isEmpty

        // Desabilita pull-to-refresh durante a busca para evitar refresh acidental
        tableView.refreshControl = isSearching ? nil : refreshControl

        emptySearchView.isHidden = !noResults
        tableView.accessibilityIdentifier = "exchangeSearch.list"

        if noResults {
            tableView.isHidden = true
        } else if filteredExchanges.isEmpty && !isSearching {
            showEmpty()
        } else {
            showExchanges(filteredExchanges, animated: animated)
        }
    }

    private func showSkeleton() {
        tableView.isHidden = false
        emptySearchView.isHidden = true
        var snap = Snapshot()
        snap.appendSections([.skeleton])
        snap.appendItems((0..<8).map { _ in Item.skeleton(UUID()) }, toSection: .skeleton)
        dataSource.apply(snap, animatingDifferences: false)
    }

    private func showExchanges(_ exchanges: [Exchange], animated: Bool = false) {
        tableView.isHidden = false
        emptySearchView.isHidden = true
        var snap = Snapshot()
        snap.appendSections([.exchanges])
        snap.appendItems(exchanges.map { Item.exchange($0) }, toSection: .exchanges)
        // apply async: o diff é calculado em background, main thread fica livre
        Task {
            await dataSource.apply(snap, animatingDifferences: animated)
        }
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

// MARK: - UISearchResultsUpdating

extension ExchangeListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchSubject.send(searchController.searchBar.text ?? "")
    }
}

// MARK: - UITableViewDelegate

extension ExchangeListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case .exchange(let exchange) = dataSource.itemIdentifier(for: indexPath) else { return }
        coordinator?.showDetail(for: exchange)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let source = searchText.isEmpty ? allExchanges : filteredExchanges
        guard indexPath.row == source.count - 1 else { return }
        Task { await viewModel.loadMore() }
    }
}
