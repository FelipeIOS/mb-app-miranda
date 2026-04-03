import SwiftUI

@main
struct QuerosermBApp: App {
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var container: DependencyContainer
    @StateObject private var listViewModel: ExchangeListViewModel

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        let container = DependencyContainer(testMode: isUITesting)
        let listViewModel = ExchangeListViewModel(
            getExchangeList: container.makeGetExchangeListUseCase()
        )
        _coordinator = StateObject(wrappedValue: AppCoordinator())
        _container = StateObject(wrappedValue: container)
        _listViewModel = StateObject(wrappedValue: listViewModel)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                ExchangeListView()
                    .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                        switch destination {
                        case .exchangeDetail(let exchange):
                            ExchangeDetailView(
                                exchange: exchange,
                                viewModel: ExchangeDetailViewModel(
                                    getExchangeDetail: container.makeGetExchangeDetailUseCase(),
                                    getExchangeAssets: container.makeGetExchangeAssetsUseCase(),
                                    detailCache: container.exchangeDetailCache
                                )
                            )
                        case .search:
                            ExchangeSearchView(viewModel: listViewModel)
                        }
                    }
            }
            .environmentObject(coordinator)
            .environmentObject(listViewModel)
            .preferredColorScheme(.dark)
        }
    }
}
