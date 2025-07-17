import LoggingKit
import Neptune
import TWUI

final class AccountDetailsV3CurrencySelectorView: UIView {
    private var viewModel: AccountDetailsV3CurrencySelectorViewModel?

    private let titleLabel = StackLabel().with {
        $0.setStyle(\.largeBodyBold)
        $0.semanticTextColor = \.content.primary
    }

    private let subtitleLabel = StackLabel().with {
        $0.setStyle(\.defaultBody)
    }

    private let imageView = UIImageView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.widthAnchor.constraint(equalToConstant: 16).isActive = true
        $0.heightAnchor.constraint(equalToConstant: 16).isActive = true
    }

    private lazy var topStackView = UIStackView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = theme.spacing.horizontal.value4
        $0.addArrangedSubviews([
            titleLabel,
        ])
    }

    private lazy var stackView = UIStackView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.alignment = .center
        $0.distribution = .fillProportionally
        $0.addArrangedSubviews([
            topStackView,
            subtitleLabel,
        ])
    }

    private lazy var dropdownButton = UIButton().with {
        $0.apply(radius: \.medium)
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(stackViewTapped), for: .touchDown)
        $0.addTarget(self, action: #selector(unhighlight), for: .touchUpInside)
        $0.addTarget(self, action: #selector(unhighlight), for: .touchUpOutside)
        $0.addTarget(self, action: #selector(unhighlight), for: .touchCancel)
    }

    // MARK: - Initializers

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("\(#function) not implemented")
    }

    init() {
        super.init(frame: .zero)
        setupView()
    }

    // MARK: - Setups

    private func setupView() {
        isAccessibilityElement = true
        backgroundColor = .clear
        addSubviewUsingAutoLayout(stackView)
        addSubview(dropdownButton)
        stackView.constrainToSuperview()
        constrainDropdownButton()
    }
}

extension AccountDetailsV3CurrencySelectorView {
    func configure(with viewModel: AccountDetailsV3CurrencySelectorViewModel) {
        self.viewModel = viewModel
        titleLabel.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)

        if viewModel.isOnTapEnabled {
            topStackView.insertArrangedSubview(imageView, below: titleLabel)
            imageView.image = Icons.chevronDown.image
        }
    }
}

private extension AccountDetailsV3CurrencySelectorView {
    @objc
    func highlight() {
        guard let viewModel, viewModel.isOnTapEnabled else { return }
        dropdownButton.backgroundColor = theme.color.background.screen.highlighted
    }

    @objc
    func unhighlight() {
        dropdownButton.backgroundColor = .clear
    }

    @objc
    func stackViewTapped() {
        guard let viewModel else { return }
        highlight()
        viewModel.onTap?()
    }

    func constrainDropdownButton() {
        NSLayoutConstraint.activate([
            dropdownButton.leadingAnchor.constraint(
                equalTo: stackView.leadingAnchor,
                constant: -theme.spacing.horizontal.betweenChips
            ),
            dropdownButton.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -theme.spacing.horizontal.betweenChips),
            dropdownButton.bottomAnchor.constraint(
                equalTo: stackView.bottomAnchor,
                constant: theme.spacing.horizontal.betweenChips
            ),
            dropdownButton.trailingAnchor.constraint(
                equalTo: stackView.trailingAnchor,
                constant: theme.spacing.horizontal.betweenChips
            ),
        ])
    }
}
