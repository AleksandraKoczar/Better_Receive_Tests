import UIKit

public protocol AppReviewNudge {
    var rule: Bool { get async throws }
}

public protocol AppReviewNudgePresenter {
    func nudgeIfNeeded(_ nudge: some AppReviewNudge, in windowScene: UIWindowScene?)
}
