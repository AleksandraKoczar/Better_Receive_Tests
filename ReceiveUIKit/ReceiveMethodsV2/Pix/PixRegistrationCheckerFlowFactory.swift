import Foundation
import TWFoundation
import UIKit
import WiseCore

// sourcery: AutoEquatableForTest
public enum PixRegistrationCheckerFlowResult {
    case finished(pixRegistered: Bool)
}

// sourcery: AutoMockable
public protocol PixRegistrationCheckerFlowFactory {
    func make(
        profileId: ProfileId,
        hostViewController: UIViewController
    ) -> any Flow<PixRegistrationCheckerFlowResult>
}

public struct PixRegistrationCheckerFlowFactoryImpl: PixRegistrationCheckerFlowFactory {
    public init() {}

    public func make(
        profileId: ProfileId,
        hostViewController: UIViewController
    ) -> any Flow<PixRegistrationCheckerFlowResult> {
        PixRegistrationCheckerFlow(
            profileId: profileId,
            hostViewController: hostViewController
        )
    }
}
