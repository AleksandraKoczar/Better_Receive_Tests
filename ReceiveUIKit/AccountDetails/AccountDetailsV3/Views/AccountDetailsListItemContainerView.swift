import LoggingKit
import Neptune
import TWFoundation
import UIKit

final class AccountDetailsListItemContainerView: UIView {
    private enum Constants {
        static let rowValueStyle = LabelStyle.largeBodyBold.with {
            $0.semanticColor = \.content.primary
            $0.paragraphSpacing = 0
        }

        static let obfuscatedRowValueStyle = { (_: SemanticContext) in
            Constants.rowValueStyle.with {
                $0.semanticFont = \.screenTitle
                $0.maximumLineHeight = 32
            }
        }
    }

    private lazy var accountDetailsStackView = UIStackView(axis: .vertical).with {
        $0.layer.backgroundColor = theme.color.background.neutral.normal.resolvedCGColor(with: traitCollection)
        $0.apply(radius: theme.radius.radius24)
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = .init(.init(
            horizontal: theme.spacing.horizontal.value12,
            vertical: theme.spacing.horizontal.value8
        ))
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        accountDetailsStackView.layer.borderColor = theme.color.background.neutral.normal.resolvedCGColor(with: traitCollection)
    }

    func setupView() {
        backgroundColor = .clear
        addSubview(accountDetailsStackView)
        accountDetailsStackView.constrainToSuperview()
    }

    func makeAccountDetailsListItemView(
        viewModel: ListItemWithDescriptionViewModel
    ) -> UIView {
        let view = StackAccountDetailsListItemWithDescriptionView()
        view.setStyle(
            AccountDetailsListItemViewStyle(
                value: Constants.rowValueStyle
            )
        )

        view.configure(
            with: viewModel
        )
        view.padding = theme.padding.horizontal.value12
        return view
    }

    func configure(with model: AccountDetailsV3MethodViewModel) {
        accountDetailsStackView.removeAllArrangedSubviews()

        let views = model.items
            .map(mapItemViewModel(_:))
            .map(makeAccountDetailsListItemView(viewModel:))

        accountDetailsStackView.addArrangedSubviews(views)

        if let footerViewModel = model.footer {
            let footerView = makeFooterButton(viewModel: footerViewModel)
            accountDetailsStackView.addArrangedSubview(.spacer(theme.spacing.vertical.value12))
            accountDetailsStackView.addArrangedSubview(footerView)
            accountDetailsStackView.setCustomSpacing(
                theme.spacing.vertical.value8,
                after: footerView
            )
            accountDetailsStackView.addArrangedSubview(UIView())
        }

        accountDetailsStackView.isHidden = accountDetailsStackView.arrangedSubviews.isEmpty
    }
}

// MARK: - Mapping Helpers

private extension AccountDetailsListItemContainerView {
    func mapItemViewModel(
        _ item: AccountDetailsV3MethodViewModel.ItemViewModel
    ) -> ListItemWithDescriptionViewModel {
        let description: MarkupLabelModel? = {
            guard let information = item.information else { return nil }
            let action = MarkupTapAction {
                item.handleMarkup?(information)
            }
            return MarkupLabelModel(text: information.value, action: action)
        }()

        let action: Action? = item.action.map { action in
            Action(
                image: action.icon,
                discoverabilityTitle: action.accessibilityLabel,
                handler: {
                    action.handleAction?(action.type)
                }
            )
        }

        return ListItemWithDescriptionViewModel(
            title: item.title,
            subtitle: item.body,
            description: description,
            action: action
        )
    }

    func makeFooterButton(
        viewModel: AccountDetailsV3MethodViewModel.FooterViewModel
    ) -> LargeButtonView {
        switch viewModel {
        case let .button(buttonViewModel):
            LargeButtonView(
                title: buttonViewModel.title,
                style: buttonViewModel.style,
                handler: {
                    buttonViewModel.action()
                }
            )
        }
    }
}
