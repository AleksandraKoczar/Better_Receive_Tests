import TWUI

// sourcery: AutoMockable
protocol PaymentRequestOnboardingView: AnyObject {
    func configure(with viewModel: PaymentRequestOnboardingViewModel)
    func showHud()
    func hideHud()
}

final class PaymentRequestOnboardingViewController: AbstractViewController {
    private let presenter: PaymentRequestOnboardingPresenter

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView(contentView: stackView).with {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var stackView = UIStackView(
        arrangedSubviews: [
            headerView,
            .spacer(.defaultSpacing * 2),
            imageView,
            .spacer(.defaultSpacing * 2),
            summaryStackView,
        ],
        axis: .vertical
    ).with {
        $0.alignment = .center
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let headerView = LargeTitleView().with {
        $0.padding = .horizontal(.defaultSpacing)
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }()

    private lazy var summaryStackView = UIStackView().with {
        $0.axis = .vertical
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var footerView = FooterView()

    init(presenter: PaymentRequestOnboardingPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "PaymentRequestOnboardingView"
        presenter.start(with: self)
        setupSubviews()
    }

    private func setupSubviews() {
        view.backgroundColor = theme.color.background.screen.normal
        view.addSubview(scrollView)

        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        scrollView.constrainToSuperview(.contentArea)
        view.addSubview(footerView)
    }

    private func configureSummaries(viewModels: [PaymentRequestOnboardingViewModel.SummaryViewModel]) {
        summaryStackView.removeAllArrangedSubviews()
        summaryStackView.addArrangedSubviews(
            viewModels.map {
                let summaryView = StackSummaryView()
                summaryView.configure(
                    with: .init(
                        title: $0.title,
                        description: $0.description,
                        icon: $0.icon
                    )
                )
                return summaryView
            }
        )
    }
}

// MARK: - PaymentRequestOnboardingView

extension PaymentRequestOnboardingViewController: PaymentRequestOnboardingView {
    func configure(with viewModel: PaymentRequestOnboardingViewModel) {
        headerView.configure(
            with: LargeTitleViewModel(
                title: viewModel.titleText,
                description: viewModel.subtitleText
            )
        )
        imageView.image = viewModel.image
        configureSummaries(viewModels: viewModel.summaryViewModels)
        footerView.primaryViewModel = .init(viewModel.footerButtonAction)
    }
}

// MARK: - HasPreDismissAction

extension PaymentRequestOnboardingViewController: HasPreDismissAction {
    func performPreDismissAction(ofType type: TWUI.DismissActionType) {
        if case .modalDismissal = type {
            presenter.dismissTapped()
        }
    }
}
