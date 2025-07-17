import Foundation
import Neptune
import UIKit

public protocol ActionListRouter: AnyObject {
    func showInfoModal(title: String, message: String)
}

public final class ActionListRouterImpl: ActionListRouter {
    // MARK: Private properties

    public weak var navigationHost: UIViewController?

    // MARK: Public methods

    public init() {}

    public func showInfoModal(title: String, message: String) {
        navigationHost?.presentInfoSheet(viewModel: InfoSheetViewModel(
            title: title,
            info: .text(message)
        ))
    }
}
