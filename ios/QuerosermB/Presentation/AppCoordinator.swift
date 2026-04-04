import UIKit

/// Centraliza toda a navegação do app (MVVM-C).
@MainActor
final class AppCoordinator {

    let navigationController: UINavigationController
    private let container: DependencyContainer

    private lazy var listViewModel = ExchangeListViewModel(
        getExchangeList: container.makeGetExchangeListUseCase()
    )

    init(navigationController: UINavigationController, container: DependencyContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let vc = ExchangeListViewController(viewModel: listViewModel, coordinator: self)
        navigationController.setViewControllers([vc], animated: false)
    }

    func showDetail(for exchange: Exchange) {
        let vm = ExchangeDetailViewModel(
            getExchangeDetail: container.makeGetExchangeDetailUseCase(),
            getExchangeAssets: container.makeGetExchangeAssetsUseCase(),
            detailCache: container.exchangeDetailCache
        )
        let vc = ExchangeDetailViewController(exchange: exchange, viewModel: vm, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func showSearch() {
        let vc = ExchangeSearchViewController(viewModel: listViewModel, coordinator: self)
        navigationController.pushViewController(vc, animated: true)
    }

    func pop() {
        navigationController.popViewController(animated: true)
    }
}
