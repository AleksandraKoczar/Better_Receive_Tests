import BalanceKit
import LoggingKit
import Neptune
import TransferResources
import UIKit

struct AccountDetailsInfoFooterViewModel {
    enum Style {
        case accent
        case link
    }

    let title: String
    let style: Style
    let action: () -> Void
}

struct AccountDetailsInfoHeaderViewModel {
    struct ShareButton {
        let title: String
        let action: (UIView) -> Void
    }

    var avatarViewModel: AvatarViewModel
    var title: String
    var description: String
    var shareButton: ShareButton?
}

struct AccountDetailsInfoRowViewModel {
    var title: String
    var information: String
    var isObfuscated: Bool
    var action: Action?
}

struct AccountDetailsReceiveOptionInfoViewModel {
    var header: AccountDetailsInfoHeaderViewModel?
    var rows: [AccountDetailsInfoRowViewModel]
    var footer: AccountDetailsInfoFooterViewModel?
}

final class AccountDetailsReceiveOptionInfoView: UIView {
    enum Constants {
        static let cornerRadius: CGFloat = 10
        static let rowValueStyle = LabelStyle.largeBody.with {
            $0.semanticColor = \.content.primary
            $0.paragraphSpacing = 0
        }

        static let linkButtonHeight: CGFloat = 56

        static let obfuscatedRowValueStyle = { (_: SemanticContext) in
            Constants.rowValueStyle.with {
                $0.semanticFont = \.screenTitle
                $0.maximumLineHeight = 32
            }
        }
    }

    private var edgeConstraints: EdgeConstraints?
    public var padding: UIEdgeInsets = .zero {
        didSet {
            edgeConstraints?.update(constant: padding)
        }
    }

    private lazy var containerView = UIView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.backgroundColor = theme.color.background.neutral.normal
        $0.layer.cornerRadius = Constants.cornerRadius
    }

    private var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.alignment = .fill
        return sv
    }()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    func configure(with model: AccountDetailsReceiveOptionInfoViewModel) {
        stackView.removeAllArrangedSubviews()
        if let header = model.header {
            stackView.addArrangedSubview(makeHeader(with: header))
        }
        stackView.addArrangedSubviews(model.rows.enumerated().map { _, rowModel in
            makeRow(
                with: rowModel
            )
        })
        if let footer = makeFooter(with: model) {
            stackView.addArrangedSubview(footer)
        }
    }

    private func makeHeader(with viewModel: AccountDetailsInfoHeaderViewModel) -> LegacyStackListItemView {
        let header = LegacyStackListItemView()
        let style = LegacyListItemViewStyle(
            title: LabelStyle.bodyTitle,
            value: LabelStyle.defaultBody,
            avatar: .size48
        )
        header.setStyle(style)
        header.setSeparatorHidden(false)
        header.view.addAvatarBorder()
        var action: Action?
        if let buttonTitle = viewModel.shareButton?.title {
            action = Action(
                title: buttonTitle,
                handler: { [unowned header] in
                    viewModel.shareButton?.action(header)
                }
            )
        }

        header.configure(
            with: LegacyListItemViewModel(
                title: viewModel.title,
                subtitle: viewModel.description,
                avatar: viewModel.avatarViewModel,
                action: action
            )
        )
        return header
    }

    private func makeRow(with viewModel: AccountDetailsInfoRowViewModel) -> LegacyStackListItemView {
        let view = LegacyStackListItemView()
        view.setStyle(.init(
            title: LabelStyle.defaultBody,
            value: viewModel.isObfuscated
                ? Constants.obfuscatedRowValueStyle(self)
                : Constants.rowValueStyle
        ))

        view.configure(
            with: LegacyListItemViewModel(
                title: viewModel.title,
                subtitle: viewModel.isObfuscated
                    // use fixed number of characters to avoid truncating text
                    ? String(repeating: "·", count: 10)
                    : viewModel.information,
                action: viewModel.action
            )
        )
        return view
    }

    private func makeFooter(with viewModel: AccountDetailsReceiveOptionInfoViewModel) -> LargeButtonView? {
        guard let footer = viewModel.footer else { return nil }

        return {
            switch footer.style {
            case .accent:
                let b = LargeButtonView(title: footer.title, handler: footer.action)
                b.setStyle(.largePrimary)
                return b
            case .link:
                let b = LargeButtonView(title: footer.title, handler: footer.action)
                b.setStyle(.largeTertiary)

                b.heightAnchor.constraint(
                    equalToConstant: Constants.linkButtonHeight
                ).isActive = true
                return b
            }
        }()
    }

    private func setupSubviews() {
        addSubview(containerView)
        containerView.addSubview(stackView)
        edgeConstraints = containerView.constrainToSuperview()
        stackView.constrainToSuperview()
    }
}
