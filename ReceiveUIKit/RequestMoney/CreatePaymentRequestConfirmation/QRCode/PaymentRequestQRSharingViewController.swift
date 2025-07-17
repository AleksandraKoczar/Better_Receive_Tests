import LoggingKit
import Neptune
import TWFoundation

// sourcery: AutoMockable
protocol PaymentRequestQRSharingView: AnyObject {
    func configure(with viewModel: PaymentRequestQRSharingViewModel)
}

final class PaymentRequestQRSharingViewController: BottomSheetViewController {
    private let presenter: PaymentRequestQRSharingPresenter
    private let autoBrightnessAdjuster: AutoBrightnessAdjuster

    // MARK: - Subviews

    private let avatarView = AvatarView().with {
        $0.contentMode = .center
        $0.setStyle(.size56)
    }

    private let avatarContainer = UIView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let titleLabel = Label(style: \.subsectionTitle)
    private let subtitleLabel = Label(style: \.largeBody)

    private lazy var titleStackView = UIStackView(
        arrangedSubviews: [titleLabel, subtitleLabel],
        axis: .vertical,
        spacing: theme.spacing.vertical.value4,
        alignment: .center
    ).with {
        $0.backgroundColor = .clear
    }

    private let qrCodeImageView = UIImageView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.layer.magnificationFilter = .nearest
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
    }

    private lazy var qrCodeStackView = UIStackView(
        arrangedSubviews:
        [
            makeHorizontalSpacingPlaceHolder(),
            qrCodeImageView,
            makeHorizontalSpacingPlaceHolder(),
        ],
        axis: .horizontal,
        alignment: .fill
    ).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var topStackView = UIStackView(arrangedSubviews: [
        avatarContainer,
        .spacer(theme.spacing.vertical.value8),
        titleStackView,
        .spacer(),
        qrCodeStackView,
    ]).with {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.distribution = .fill
    }

    private let requestDetailsHeader = StackSectionHeaderView()

    private let requestDetailsStackView = UIStackView().with {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
    }

    // MARK: - Lifecycle

    init(
        presenter: PaymentRequestQRSharingPresenter,
        autoBrightnessAdjuster: AutoBrightnessAdjuster
    ) {
        self.presenter = presenter
        self.autoBrightnessAdjuster = autoBrightnessAdjuster
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        hardFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        autoBrightnessAdjuster.startAppStateMonitoring()
        setupSubviews()
        presenter.start(with: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoBrightnessAdjuster.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoBrightnessAdjuster.viewWillDisappear()
    }
}

// MARK: - Helpers

private extension PaymentRequestQRSharingViewController {
    func makeHorizontalSpacingPlaceHolder() -> UIView {
        UIView().with {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: theme.spacing.horizontal.componentDefault * 2.5).isActive = true
        }
    }

    func setupSubviews() {
        arrangedSubviews = [
            topStackView,
            requestDetailsStackView,
            .spacer(),
        ]
        avatarContainer.addSubview(avatarView)
        setupSubviewConstraints()
    }

    func setupSubviewConstraints() {
        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            avatarContainer.heightAnchor.constraint(equalTo: avatarView.heightAnchor),
        ])
    }
}

// MARK: - PaymentRequestQRSharingView

extension PaymentRequestQRSharingViewController: PaymentRequestQRSharingView {
    func configure(with viewModel: PaymentRequestQRSharingViewModel) {
        avatarView.configure(with: viewModel.avatar)
        titleLabel.configure(with: viewModel.title)
        subtitleLabel.configure(with: viewModel.subtitle)

        qrCodeImageView.image = viewModel.qrCodeImage
        requestDetailsHeader.configure(with: SectionHeaderViewModel(title: viewModel.requestDetailsHeader))
        let listItems = viewModel.requestItems.map { listItemViewModel in
            let listItem = LegacyStackListItemView()
            let viewModel = LegacyListItemViewModel(
                title: listItemViewModel.title,
                subtitle: listItemViewModel.value
            )
            listItem.configure(with: viewModel)
            return listItem
        }
        requestDetailsStackView.removeAllArrangedSubviews()
        requestDetailsStackView.addArrangedSubview(requestDetailsHeader)
        requestDetailsStackView.addArrangedSubviews(listItems)
        updatePreferredContentSize()
    }
}
