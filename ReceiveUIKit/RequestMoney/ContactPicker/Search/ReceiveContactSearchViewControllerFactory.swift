import Combine
import ContactsKit
import Foundation
import UIKit
import UserKit
import WiseCore

// sourcery: AutoEquatableForTest, Buildable
public enum ReceiveContactPickerSearchResult {
    case selected(Contact)
    case selectedContinueWithLink
    case finishedWithoutSelection
}

// sourcery: AutoMockable
public protocol ReceiveContactSearchViewControllerFactory {
    func makeContactSearch(
        profile: Profile,
        navigationController: UINavigationController
    ) -> ReceiveContactSearchViewControllerFactoryMakeResult
}

public struct ReceiveContactSearchViewControllerFactoryMakeResult {
    let viewController: UIViewController
    let resultPublisher: AnyPublisher<ReceiveContactPickerSearchResult, Never>

    public init(
        viewController: UIViewController,
        resultPublisher: AnyPublisher<ReceiveContactPickerSearchResult, Never>
    ) {
        self.viewController = viewController
        self.resultPublisher = resultPublisher
    }
}
