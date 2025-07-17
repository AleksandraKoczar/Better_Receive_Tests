import Combine
import CombineSchedulers
import ContactsKit
import Neptune
import UIKit

// sourcery: AutoMockable
protocol AvatarLoadableNavigationOptionTableViewCell: AnyObject {
    func configure(with viewModel: OptionViewModel)
}

/// TODO: This view is implemented as a workaround for fetching the contact avatar
/// from a publisher. And it should be removed after a replacement implemented on
/// ContactsUIKit
/// https://transferwise.atlassian.net/browse/RA-3989
final class AvatarLoadableNavigationOptionTableViewCellImpl: ContainerTableViewCell<NavigationOptionView>, AvatarLoadableNavigationOptionTableViewCell {
    static var estimatedRowHeight: CGFloat = 80

    var presenter: AvatarLoadableNavigationOptionTableViewCellPresenter?

    override static func preferredPadding(context: SemanticContext) -> UIEdgeInsets {
        context.theme.padding.horizontal.value16
    }

    override func setupSubviews() {
        super.setupSubviews()
        setSeparatorHidden(true)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        presenter?.prepareForReuse()
        setSeparatorHidden(true)
    }

    func setLeadingAvatarViewStyle(_ style: AvatarViewStyle) {
        view.setLeadingAvatarViewStyle(style)
    }

    override func configure(with viewModel: OptionViewModel) {
        super.configure(with: viewModel)
        isEnabled = viewModel.isEnabled
    }
}
