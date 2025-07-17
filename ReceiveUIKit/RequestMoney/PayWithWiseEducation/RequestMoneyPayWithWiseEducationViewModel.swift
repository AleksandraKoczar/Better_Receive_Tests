import Neptune
import UIKit

// sourcery: AutoEquatableForTest
struct RequestMoneyPayWithWiseEducationViewModel {
    let image: UIImage
    let title: String
    let subtitle: String
    let description: MarkupLabel?
    let action: Action
}

extension RequestMoneyPayWithWiseEducationViewModel {
    // sourcery: AutoEquatableForTest
    struct MarkupLabel {
        let text: String
        // sourcery: skipEquality
        let action: () -> Void
    }
}
