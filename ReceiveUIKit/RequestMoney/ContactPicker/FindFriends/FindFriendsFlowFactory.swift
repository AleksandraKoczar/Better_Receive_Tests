import TWFoundation
import UIKit

// sourcery: AutoMockable
protocol FindFriendsFlowFactory {
    func makeFlow(
        navigationController: UINavigationController
    ) -> any Flow<Void>
}

public class FindFriendsFlowFactoryImpl: FindFriendsFlowFactory {
    private let helpCenterArticleFactory: HelpCenterArticleFactory

    init(
        helpCenterArticleFactory: HelpCenterArticleFactory
    ) {
        self.helpCenterArticleFactory = helpCenterArticleFactory
    }

    func makeFlow(
        navigationController: UINavigationController
    ) -> any Flow<Void> {
        FindFriendsFlow(
            navigationController: navigationController,
            helpCenterArticleFactory: helpCenterArticleFactory,
            urlOpener: UIApplication.shared
        )
    }
}
