import SwiftUI

/// Centraliza toda a navegação do app (MVVM-C).
/// Vive no topo da hierarquia (`QuerosermBApp`) e é injetado via `@EnvironmentObject`.
@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Destinos tipados
    enum Destination: Hashable {
        case exchangeDetail(Exchange)
        case search
    }

    // MARK: - Estado
    @Published var path = NavigationPath()

    // MARK: - Navegação
    func push(_ destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
