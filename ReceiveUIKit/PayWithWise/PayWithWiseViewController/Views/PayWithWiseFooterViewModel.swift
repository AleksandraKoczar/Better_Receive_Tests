import Foundation
import Neptune

struct PayWithWiseFooterViewModel {
    let firstButton: FirstButtonConfig
    let secondButton: SecondButtonConfig?

    struct SecondButtonConfig {
        let title: String
        let style: SecondaryButtonStyle
        let isEnabled: Bool
        let action: Action.Handler

        enum SecondaryButtonStyle {
            case secondary
            case secondaryNeutral
            case negative
            case tertiary
        }
    }

    struct FirstButtonConfig {
        let title: String
        let style: PrimaryButtonStyle
        let isEnabled: Bool
        let action: Action.Handler

        enum PrimaryButtonStyle {
            case primary
            case secondary
            case secondaryNeutral
            case negative
        }
    }
}
