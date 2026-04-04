import UIKit
import Combine

final class ExchangeSearchViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: ExchangeListViewModel
    private weak var coordinator: AppCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State
    private var searchText: String = "" {
        didSet { applyFilter() }
    }
    private var filteredExchanges: [Exchange] = []

    // MARK: - UI
    private let searchBar = UISearchBar()
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .mbPrimary
        tv.separatorStyle  = .none
        tv.register(ExchangeCardCell.self, forCellReuseIdentifier: ExchangeCardCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 88
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tv.keyboardDismissMode = .onDrag
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
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
        setupSearchBar()
        setupLayout()
        tableView.dataSource = self
        tableView.delegate   = self
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupNavigation() {
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.prefersLargeTitles = false
        view.backgroundColor = .mbPrimary
    }

    private func setupSearchBar() {
        searchBar.placeholder              = "Nome, slug ou ID"
        searchBar.barStyle                 = .black
        searchBar.searchBarStyle           = .minimal
        searchBar.tintColor                = .mbAccent
        searchBar.searchTextField.textColor = .mbText
        searchBar.searchTextField.font     = .mbBody()
        searchBar.searchTextField.backgroundColor = .mbSurface
        searchBar.searchTextField.accessibilityIdentifier = "exchangeSearch.field.query"
        searchBar.delegate                 = self
        searchBar.showsCancelButton        = true
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        if let cancel = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancel.setTitle("Cancelar", for: .normal)
            cancel.setTitleColor(.mbAccent, for: .normal)
            cancel.accessibilityIdentifier = "exchangeSearch.button.cancel"
        }
    }

    private func setupLayout() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptySearchView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptySearchView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            emptySearchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptySearchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptySearchView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$state
            .sink { [weak self] _ in self?.applyFilter() }
            .store(in: &cancellables)
    }

    // MARK: - Filter

    private func applyFilter() {
        guard case .success(let all) = viewModel.state else {
            filteredExchanges = []
            tableView.reloadData()
            return
        }
        filteredExchanges = ExchangeListViewModel.filterExchanges(all, query: searchText)

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEmpty = !trimmed.isEmpty && filteredExchanges.isEmpty
        emptySearchView.isHidden = !isEmpty
        tableView.isHidden       = isEmpty

        tableView.reloadData()
        tableView.accessibilityIdentifier = "exchangeSearch.list"
    }
}

// MARK: - UISearchBarDelegate

extension ExchangeSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        coordinator?.pop()
    }
}

// MARK: - UITableViewDataSource

extension ExchangeSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredExchanges.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExchangeCardCell.reuseIdentifier,
            for: indexPath
        ) as! ExchangeCardCell
        let exchange = filteredExchanges[indexPath.row]
        cell.configure(with: exchange)
        cell.accessibilityIdentifier = "exchangeList.cell.\(exchange.id)"

        // Load more when reaching last item
        if indexPath.row == filteredExchanges.count - 1 {
            Task { await viewModel.loadMore() }
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ExchangeSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exchange = filteredExchanges[indexPath.row]
        coordinator?.showDetail(for: exchange)
    }
}
