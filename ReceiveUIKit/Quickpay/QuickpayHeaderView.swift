import LoggingKit
import SwiftUI
import TransferResources
import TWUI
import UIKit

final class QuickpayHeaderView: UIView {
    // MARK: - Subviews

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            avatarView,
            titleLabel,
            actionButtonStack,
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

    private lazy var actionButtonStack = UIStackView(
        arrangedSubviews: [],
        axis: .horizontal,
        alignment: .center
    ).with {
        $0.spacing = theme.spacing.horizontal.value4
    }

    private lazy var button = SmallButtonView()

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

    func configure(with viewModel: QuickpayViewModel) {
        avatarView.configure(with: viewModel.avatar)
        titleLabel.configure(with: viewModel.title)

        actionButtonStack.removeAllArrangedSubviews()
        switch viewModel.linkType {
        case let .active(text, handler):
            button.setStyle(.smallSecondary)
            button.configure(with: .init(title: text, leadingIcon: Icons.link.image, handler: handler))
            actionButtonStack.addArrangedSubviews(button)
        case let .inactive(link):
            label.configure(with: link)
            actionButtonStack.addArrangedSubviews(label)
        }
    }
}
