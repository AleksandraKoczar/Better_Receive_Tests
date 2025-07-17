import LoggingKit
import Neptune
import UIKit

/// A copy of the Neptune ListItemView with adding a tooltip icon to the title
final class AccountDetailsListItemView: UIView, BoundingSizeCalculating {
    // MARK: - Properties

    static let preferredPadding = UIEdgeInsets(
        vertical: .defaultMargin / 2,
        horizontal: .defaultMargin
    )

    private var model: AccountDetailsListItemViewModel?
    private var style: AccountDetailsListItemViewStyle = .init()

    /// Whether value is copyable or not, default is `true`.
    var valueIsCopyable: Bool {
        get { valueLabel.isCopyable }
        set { valueLabel.isCopyable = newValue }
    }

    @available(*, unavailable)
    override var translatesAutoresizingMaskIntoConstraints: Bool {
        get { super.translatesAutoresizingMaskIntoConstraints }
        set { super.translatesAutoresizingMaskIntoConstraints = newValue }
    }

    // MARK: - Init

    init(style: AccountDetailsListItemViewStyle = .init()) {
        super.init(frame: .zero)
        setupSubviews()
        setStyle(style)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setStyle(style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    // MARK: - interface

    func configure(with model: AccountDetailsListItemViewModel) {
        self.model = model
        titleLabel.text = model.title
        valueLabel.configure(with: MarkupLabel.Model(model: model.subtitle))

        var tooltipCustomAction: UIAccessibilityCustomAction?
        if let tooltip = model.tooltip {
            tooltipIconButton.configure(with: tooltip)
            tooltipIconButton.setStyle(.iconPlain.with {
                $0.iconSize = SemanticSize.icon.size16
            })
            tooltipCustomAction = Action(
                image: tooltip.icon,
                discoverabilityTitle: tooltip.discoverabilityTitle,
                handler: tooltip.handler
            ).accessibilityAction
        }

        if let action = model.action {
            if let image = action.image,
               action.title.isEmpty {
                actionButton.isHidden = true
                iconButton.isHidden = false
                iconButton.configure(with: .init(
                    icon: image,
                    discoverabilityTitle: action.discoverabilityTitle,
                    handler: action.handler
                ))
            } else {
                actionButton.isHidden = false
                iconButton.isHidden = true
                actionButton.configure(with: .init(title: action.title, leadingIcon: action.image, handler: action.handler))
            }
            buttonTrailingSpacer.isHidden = false
            accessibilityElement.accessibilityCustomActions = [
                tooltipCustomAction,
                action.accessibilityAction,
            ].compactMap { $0 }
        } else {
            actionButton.isHidden = true
            iconButton.isHidden = true
            buttonTrailingSpacer.isHidden = true
            accessibilityElement.accessibilityCustomActions = []
        }

        accessibilityElement.accessibilityLabel = titleLabel.text
        accessibilityElement.accessibilityValue = valueLabel.text
    }

    func setStyle(_ style: AccountDetailsListItemViewStyle) {
        self.style = style
        titleLabel.setStyle(style.title)
        valueLabel.setStyle(style.value)
        actionButton.setStyle(style.buttonStyle)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        accessibilityElement.accessibilityFrameInContainerSpace = bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isAccessibilityCategoryChanged(previousTraitCollection) {
            updateLayout()
        }
    }

    var preferredMaxLayoutWidth: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        intrinsicContentSize(model: model, style: style)
    }

    static func boundingSize(
        for model: AccountDetailsListItemViewModel,
        style: AccountDetailsListItemViewStyle,
        in targetSize: CGSize,
        context: SemanticContext
    ) -> CGSize {
        let isAccessibilityCategory = context.traitCollection.isAccessibilityCategory

        let padding: UIEdgeInsets = context.theme.padding.value8.clamped(to: .vertical)
        var height = padding.sumVertical

        let buttonSize: CGSize

        if let action = model.action {
            if action.image != nil, action.title.isEmpty {
                let actionStyle: any IconButtonAppearance = .iconPlain
                buttonSize = actionStyle.boundingSize(context: context)
            } else {
                buttonSize = SmallButtonView.boundingSize(
                    for: .init(title: action.title) {},
                    style: .smallPrimary,
                    in: targetSize,
                    context: context
                )
            }
        } else {
            buttonSize = .zero
        }

        let buttonSpacing = isAccessibilityCategory ? context.theme.spacing.horizontal.value0 : context.theme.spacing.horizontal.betweenChips
        let contentTargetWidth = targetSize.width
            - (isAccessibilityCategory ? .zero : buttonSize.width + buttonSpacing)
            - padding.sumVertical

        let titleTargetSize = CGSize(
            width: max(contentTargetWidth, 0),
            height: max(targetSize.height, 0)
        )

        let valueTargetSize = isAccessibilityCategory
            ? CGSize(
                width: contentTargetWidth,
                height: max(targetSize.height, 0)
            )
            : titleTargetSize

        let titleHeight = Label.boundingSize(
            for: model.title,
            style: style.title,
            in: titleTargetSize,
            context: context
        ).height

        let valueHeight = MarkupLabel.boundingSize(
            for: .init(model: model.subtitle),
            style: style.value,
            in: valueTargetSize,
            context: context
        ).height

        let textSpacing = context.theme.spacing.vertical.value4
        if isAccessibilityCategory {
            height += titleHeight
            height += textSpacing + valueHeight
            height += textSpacing + buttonSize.height
        } else {
            let textHeight = titleHeight + textSpacing + valueHeight
            height += textHeight
        }

        let minHeight = context.theme.size.value72.height
        return CGSize(
            width: targetSize.width,
            height: max(minHeight, height)
        )
    }

    // MARK: - Private methods

    private func setupSubviews() {
        super.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.constrainToSuperview(
            .edges,
            insets: theme.padding.value8.clamped(to: .vertical)
        )

        updateLayout()
        accessibilityElements = [accessibilityElement]
        valueIsCopyable = true
    }

    private func updateLayout() {
        if traitCollection.isAccessibilityCategory {
            labelsAndButtonStackView.axis = .vertical
            buttonContainer.addArrangedSubview(buttonTrailingSpacer)
        } else {
            labelsAndButtonStackView.axis = .horizontal
            buttonTrailingSpacer.removeFromSuperview()
        }

        labelsContainerView.spacing = theme.spacing.vertical.value4
    }

    // Accessibility

    private lazy var accessibilityElement: UIAccessibilityElement = {
        let element = UIAccessibilityElement(accessibilityContainer: self)
        element.isAccessibilityElement = true
        element.accessibilityTraits = .staticText
        return element
    }()

    // MARK: - Subviews

    private let titleLabel: Label = {
        let l = Label()
        l.numberOfLines = 0
        return l
    }()

    private let valueLabel = MarkupLabel()

    private lazy var horizontalContainer: UIStackView = {
        let s = UIStackView(
            arrangedSubviews: [
                titleLabel,
                tooltipIconButton,
                UIView().with {
                    $0.setContentHuggingPriority(
                        .defaultLow,
                        for: .horizontal
                    )
                },
            ]
        )
        s.alignment = .center
        s.spacing = theme.spacing.horizontal.value4
        s.distribution = .fill
        return s
    }()

    private lazy var labelsContainerView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [horizontalContainer, valueLabel])
        sv.axis = .vertical
        return sv
    }()

    private let actionButton = SmallButtonView()
    private let iconButton = IconButtonView()

    private lazy var tooltipIconButton = IconButtonView()

    // spacer view used to align button to the left in accessibility layout
    let buttonTrailingSpacer = UIView.spacer()

    private lazy var buttonContainer: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [actionButton, iconButton])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.spacing = .zero
        sv.alignment = .center
        return sv
    }()

    private lazy var labelsAndButtonStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [labelsContainerView, buttonContainer])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.spacing = theme.spacing.horizontal.componentDefault
        return sv
    }()

    private lazy var contentView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [labelsAndButtonStackView])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.spacing = theme.spacing.horizontal.componentDefault
        sv.alignment = .center
        return sv
    }()
}

final class StackAccountDetailsListItemView: StackContainerView<AccountDetailsListItemView> {
    override static func preferredPadding(context: SemanticContext) -> UIEdgeInsets {
        LegacyListItemView.preferredPadding(context: context)
    }

    override func setupSubviews() {
        super.setupSubviews()
        setSeparatorHidden(true)
    }
}
