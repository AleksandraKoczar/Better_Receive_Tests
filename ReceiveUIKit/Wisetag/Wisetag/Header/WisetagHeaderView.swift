import LoggingKit
import SwiftUI
import TransferResources
import TWUI
import UIKit

final class WisetagHeaderView: UIView {
    // MARK: - Subviews

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            avatarView,
            titleLabel,
            stackLabel,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.componentDefault,
        alignment: .center
    )

    private let avatarView = AvatarView().with {
        var style = AvatarViewStyle.size72
        $0.setStyle(style)
    }

    private let titleLabel = StackLabel().with {
        $0.setStyle(\.smallDisplay.centered)
    }

    private lazy var stackLabel = UIStackView(
        arrangedSubviews: [
            linkIcon,
            link,
        ],
        axis: .horizontal,
        alignment: .center
    ).with {
        $0.spacing = theme.spacing.horizontal.value4
    }

    private lazy var linkIcon = UIImageView().with {
        $0.contentMode = .scaleAspectFit
        $0.heightAnchor.constraint(lessThanOrEqualToConstant: 16).isActive = true
        $0.widthAnchor.constraint(lessThanOrEqualToConstant: 16).isActive = true
        $0.tintColor = theme.color.content.link.normal
    }

    private lazy var link = SmallButtonView().with {
        $0.setStyle(.smallTertiary)
    }

    private lazy var label = StackLabel().with {
        $0.setStyle(\.defaultBody)
        $0.textAlignment = .center
        $0.padding = theme.padding.horizontal.value4
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.constrainToSuperview(.contentArea)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with viewModel: WisetagHeaderViewModel) {
        avatarView.configure(with: viewModel.avatar)
        titleLabel.configure(with: viewModel.title)

        stackLabel.removeAllArrangedSubviews()
        switch viewModel.linkType {
        case let .active(text, handler):
            link.configure(with: .init(title: text, handler: handler))
            linkIcon.image = Icons.link.image
            stackLabel.addArrangedSubviews(linkIcon)
            stackLabel.addArrangedSubviews(link)
        case let .inactive(link):
            label.configure(with: link)
            stackLabel.addArrangedSubviews(label)
        }
        layoutIfNeeded()
    }
}
