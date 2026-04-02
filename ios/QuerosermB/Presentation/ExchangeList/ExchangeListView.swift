import SwiftUI

struct ExchangeListView: View {
    @StateObject private var viewModel: ExchangeListViewModel
    @Namespace private var namespace

    init() {
        let container = DependencyContainer.shared
        _viewModel = StateObject(wrappedValue: ExchangeListViewModel(
            getExchangeList: container.makeGetExchangeListUseCase()
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mbPrimary.ignoresSafeArea()

                content
            }
            .navigationTitle("Exchanges")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.mbPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await viewModel.loadExchanges() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            skeletonList
        case .success(let exchanges):
            exchangeList(exchanges)
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
                    NavigationLink {
                        ExchangeDetailView(exchange: exchange, namespace: namespace)
                    } label: {
                        ExchangeCard(exchange: exchange, namespace: namespace)
                    }
                    .buttonStyle(.plain)
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
    ExchangeListView()
        .preferredColorScheme(.dark)
}
