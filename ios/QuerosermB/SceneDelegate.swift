import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        let container   = DependencyContainer(testMode: isUITesting)

        let nav = UINavigationController()
        nav.overrideUserInterfaceStyle = .dark

        let coordinator = AppCoordinator(navigationController: nav, container: container)
        self.coordinator = coordinator

        let win = UIWindow(windowScene: windowScene)
        win.overrideUserInterfaceStyle = .dark
        win.rootViewController = nav
        win.makeKeyAndVisible()
        window = win

        coordinator.start()
    }
}
