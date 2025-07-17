import Combine
import Foundation
import LoggingKit
import Neptune
import UIKit

final class PayWithWiseHeaderView: UIView, HeaderView {
    private var cancellable: AnyCancellable?

    var contentOffset: CGPoint = .zero
    var contentInset: UIEdgeInsets = .zero
    var scrollObserver: ScrollObserver? {
        get {
            titleLabel.scrollObserver
        }
        set {
            titleLabel.scrollObserver = newValue
        }
    }

    var delegate: HeaderViewDelegate? {
        get {
            titleLabel.delegate
        }
        set {
            titleLabel.delegate = newValue
        }
    }

    var layoutDelegate: HeaderViewLayoutDelegate? {
        get {
            titleLabel.layoutDelegate
        }
        set {
            titleLabel.layoutDelegate = newValue
        }
    }

    // MARK: - Subviews

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            stackLabel,
            avatarView,
        ],
        axis: .horizontal,
        spacing: theme.spacing.vertical.componentDefault,
        alignment: .center
    ).with {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = .horizontal(.defaultMargin / 2)
    }

    private lazy var stackLabel = UIStackView(
        arrangedSubviews: [
            titleLabel,
            recipientLabel,
            descriptionLabel,
        ],
        axis: .vertical,
        spacing: theme.spacing.vertical.value4,
        alignment: .leading
    )

    private let titleLabel = LargeTitleView()

    private lazy var recipientLabel = StackLabel().with {
        $0.setStyle(\.largeBodyBold)
        $0.textAlignment = .left
    }

    private lazy var descriptionLabel = StackLabel().with {
        $0.setStyle(\.defaultBody)
        $0.textAlignment = .left
    }

    private let avatarView = AvatarView().with {
        var style = AvatarViewStyle.size56
        $0.setStyle(style)
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

    func configure(with viewModel: ViewModel) {
        cancellable = viewModel.avatarImage.sink { [weak self] in
            self?.avatarView.configure(with: $0)
        }

        titleLabel.configure(with: viewModel.title)
        recipientLabel.configure(with: viewModel.recipientName)
        descriptionLabel.configure(with: viewModel.description)

        layoutIfNeeded()
    }
}

extension PayWithWiseHeaderView {
    // sourcery: Buildable
    struct ViewModel {
        let title: LargeTitleViewModel
        let recipientName: String
        let description: String?
        let avatarImage: AnyPublisher<AvatarViewModel, Never>
    }
}
