import ReceiveUIKit
import UIKit

public final class AppReviewNudgePresenterMock: AppReviewNudgePresenter {
    public init() {}

    var nudgeIfNeededCalled = false
    public func nudgeIfNeeded(_ nudge: some AppReviewNudge, in windowScene: UIWindowScene?) {
        nudgeIfNeededCalled = true
    }
}
