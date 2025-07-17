import Foundation
import Neptune
import TWUI
import UIKit

public enum AccountDetailsStatusRouterAction: Equatable {
    public struct Info: Equatable {
        public let title: String
        public let content: String
    }

    case showInfo(Info)
}

// sourcery: AutoMockable
public protocol AccountDetailsStatusRouter {
    func route(action: AccountDetailsStatusRouterAction)
}

public final class AccountDetailsStatusRouterImpl: AccountDetailsStatusRouter {
    public weak var navigationHost: UIViewController?

    public init() {}

    public func route(action: AccountDetailsStatusRouterAction) {
        switch action {
        case let .showInfo(info):
            navigationHost?.presentInfoSheet(
                viewModel: InfoSheetViewModel(
                    title: info.title,
                    info: .text(info.content)
                )
            )
        }
    }
}
