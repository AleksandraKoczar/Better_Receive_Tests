import Foundation
import Neptune
import ReceiveKit
import UIKit

struct ReceiveRestrictionViewModel {
    let illustration: IllustrationView.Asset
    let title: String
    let body: MarkupString
    let alert: Alert?
    let sections: [ReceiveRestriction.Section]
    let footers: [Footer]

    init(restriction: ReceiveRestriction) {
        illustration = {
            let _illustration = IllustrationFactory.illustration(
                name: restriction.illustration
            ) ?? Illustrations.globe.image
            return IllustrationView.Asset.image(
                _illustration
            )
        }()
        title = restriction.title
        body = restriction.body
        alert = {
            guard let alert = restriction.alert else {
                return nil
            }
            let style: InlineAlertStyle =
                switch alert.type {
                case .positive: .positive
                case .warning: .warning
                case .negative: .negative
                }
            return Alert(
                style: style,
                viewModel: InlineAlertViewModel(message: alert.message)
            )
        }()
        sections = restriction.sections
        footers = restriction.footer.map { _footer in
            Footer(
                label: _footer.label,
                type: _footer.type
            )
        }
    }

    struct Alert {
        let style: InlineAlertStyle
        let viewModel: InlineAlertViewModel
    }

    struct Footer {
        let label: String
        let type: ReceiveRestriction.Footer.`Type`
    }
}

// MARK: - Alert Type style mapping

extension ReceiveRestriction.Section.Summary {
    var iconImage: UIImage {
        IconFactory.icon(name: icon) ?? Icons.infoCircle.image
    }
}

private extension ReceiveRestriction.Alert.`Type` {
    var inlineAlertStyle: InlineAlertStyle {
        switch self {
        case .positive:
            .positive
        case .warning:
            .warning
        case .negative:
            .negative
        }
    }
}
