import SwiftUI

/// Tela de busca **sem `.searchable`** — campo próprio no body, sem `UISearchController`, sem conflitos de Auto Layout na barra.
struct ExchangeSearchView: View {
    @ObservedObject var viewModel: ExchangeListViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().background(Color.mbSurfaceAlt)
            content
        }
        .background(Color.mbPrimary.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { fieldFocused = true }
        .onDisappear { viewModel.searchText = "" }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.mbTextMuted)
                .font(.system(size: 16))

            TextField("Nome, slug ou ID", text: $viewModel.searchText)
                .font(.mbBody)
                .foregroundColor(.mbText)
                .tint(.mbAccent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($fieldFocused)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mbTextMuted)
                }
            }

            Button("Cancelar") {
                dismiss()
            }
            .font(.mbBody)
            .foregroundColor(.mbAccent)
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
            } else if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      viewModel.displayedExchanges.isEmpty {
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
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.mbTextMuted)
            Text("Nenhum resultado")
                .font(.mbTitle)
                .foregroundColor(.mbText)
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
        let exchanges = viewModel.displayedExchanges
        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(exchanges.enumerated()), id: \.element.id) { index, exchange in
                    NavigationLink {
                        ExchangeDetailView(exchange: exchange)
                    } label: {
                        ExchangeCard(exchange: exchange)
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
    }
}
