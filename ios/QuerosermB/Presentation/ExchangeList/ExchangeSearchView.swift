import SwiftUI

/// Tela de busca **sem `.searchable`** — campo próprio no body, sem `UISearchController`, sem conflitos de Auto Layout na barra.
struct ExchangeSearchView: View {
    @ObservedObject var viewModel: ExchangeListViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @FocusState private var fieldFocused: Bool
    @State private var searchText = ""

    private var displayedExchanges: [Exchange] {
        guard case .success(let all) = viewModel.state else { return [] }
        return ExchangeListViewModel.filterExchanges(all, query: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().background(Color.mbSurfaceAlt)
            content
        }
        .background(Color.mbPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { fieldFocused = true }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.mbTextMuted)
                .font(.system(size: 16))

            TextField("Nome, slug ou ID", text: $searchText)
                .font(.mbBody)
                .foregroundColor(.mbText)
                .tint(.mbAccent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($fieldFocused)
                .accessibilityIdentifier("exchangeSearch.field.query")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mbTextMuted)
                }
            }

            Button("Cancelar") {
                coordinator.pop()
            }
            .font(.mbBody)
            .foregroundColor(.mbAccent)
            .accessibilityIdentifier("exchangeSearch.button.cancel")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.mbPrimary)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Spacer()
            ProgressView().tint(.mbGold)
            Spacer()
        case .success(let all):
            if all.isEmpty {
                EmptyStateView()
            } else if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      displayedExchanges.isEmpty {
                searchEmptyView
            } else {
                searchResultsList
            }
        case .empty:
            EmptyStateView()
        case .error(let message):
            ErrorView(message: message, embedded: true) {
                Task { await viewModel.refresh() }
            }
            .padding(.top, 40)
        }
    }

    // MARK: - Empty search

    private var searchEmptyView: some View {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.mbTextMuted)
            Text("Nenhum resultado")
                .font(.mbTitle)
                .foregroundColor(.mbText)
                .accessibilityIdentifier("exchangeSearch.empty.title")
            Text("Não encontramos exchanges para \"\(trimmed)\".")
                .font(.mbBody)
                .foregroundColor(.mbTextSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // MARK: - Results list

    private var searchResultsList: some View {
        let exchanges = displayedExchanges
        return ScrollView {
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
        .accessibilityIdentifier("exchangeSearch.list")
    }
}
