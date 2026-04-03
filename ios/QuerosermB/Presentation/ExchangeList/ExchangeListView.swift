import SwiftUI

struct ExchangeListView: View {
    @EnvironmentObject private var viewModel: ExchangeListViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color.mbPrimary.ignoresSafeArea()

            content
        }
        .accessibilityIdentifier("exchangeList.root")
        .navigationTitle("Exchanges")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.mbPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.search)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.mbGold)
                }
                .accessibilityLabel("Buscar exchanges")
                .accessibilityIdentifier("exchangeList.button.search")
            }
        }
        .task { await viewModel.loadInitialListIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            skeletonList
        case .success(let exchanges):
            if exchanges.isEmpty {
                EmptyStateView()
            } else {
                exchangeList(exchanges)
            }
        case .empty:
            EmptyStateView()
        case .error(let message):
            ErrorView(message: message) {
                Task { await viewModel.refresh() }
            }
        }
    }

    // MARK: - Skeleton loading
    private var skeletonList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<8, id: \.self) { _ in
                    ExchangeCardSkeleton()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Exchange List
    private func exchangeList(_ exchanges: [Exchange]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(exchanges.enumerated()), id: \.element.id) { index, exchange in
                    Button {
                        coordinator.push(.exchangeDetail(exchange))
                    } label: {
                        ExchangeCard(exchange: exchange)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exchangeList.cell.\(exchange.id)")
                    .onAppear {
                        if index == exchanges.count - 1 {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(.mbGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }

                if let message = viewModel.loadMoreErrorMessage {
                    Text(message)
                        .font(.mbBody)
                        .foregroundColor(.mbTextSub)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        ExchangeListView()
            .environmentObject(ExchangeListViewModel(
                getExchangeList: GetExchangeListUseCase(
                    repository: UITestStubExchangeRepository()
                )
            ))
            .environmentObject(AppCoordinator())
    }
    .preferredColorScheme(.dark)
}
